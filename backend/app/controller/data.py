import re
import os

from flask import g
from sqlalchemy import or_, type_coerce, func, text
from sqlalchemy.dialects.mysql import TEXT
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm.attributes import InstrumentedAttribute
from datetime import datetime

from app.keys import ID
from app.messages import TABLE_NOT_FOUND, USER_NO_ACCESS, COMPANY_NOT_FOUND, KEY_ERROR, MESSAGE
from app.model import db
from app.service import is_admin, document
from app.storage import PostgresDatabase
from app.utils import orm_to_json, CbsException
from run import app


def put(bag):
    data = {
        "type": bag["type"]
    }
    del bag["type"]
    if '_created' in bag:
        del bag["_created"]
    if '_deleted' in bag:
        del bag["_deleted"]

    table_name = data["type"]
    table = getattr(db, table_name)

    if table is None or not issubclass(table, (db.Base, db.CouchSync)):
        raise CbsException(TABLE_NOT_FOUND)

    for key in bag:
        data[key] = bag[key]
    # del_columns(data)

    for column in table.metadata.tables.get(table_name.lower()).columns._data:
        nullable = table.metadata.tables.get(table_name.lower()).columns._data[column].nullable
        if not nullable and not column.startswith("_") and not column == "entry_user_id" and column not in data:
            raise CbsException(KEY_ERROR, MESSAGE.get(KEY_ERROR).format(column))
        elif not column.startswith("_") and not column == "entry_user_id" and column not in data:
            data[column] = None

    pg_db = PostgresDatabase()
    _id, _rev = pg_db.store(data, new_edits=True)
    return {"ok": True, "id": _id, "rev": _rev}


def get(bag):
    table_name = bag['type']
    table = getattr(db, table_name) if hasattr(db, table_name) else None
    if table is None or not issubclass(table, (db.Base, db.CouchSync)):
        raise CbsException(TABLE_NOT_FOUND)
    query = g.tran.query(table).filter_by(_deleted='infinity', _id=bag[ID])

    entity = orm_to_json(query.one())

    if "with_related" in bag and bag["with_related"] == True:
        entity = find_relations(entity, table_name)

    return {'doc': entity}


def delete(bag):
    table_name = bag['type']
    table = getattr(db, table_name) if hasattr(db, table_name) else None
    query = g.tran.query(table).filter_by(_id=u"{}".format(bag['id']))
    query.update({"_deleted": str(datetime.now())})
    doc = query.one()
    files = doc.data["files"]
    for f in files:
        file_path = os.path.join(app.config['UPLOADED_DEFAULTS_DEST'], f["filename"])
        if os.path.exists(file_path):
            os.remove(file_path)
    return {'ok': True}


def remove(bag):
    table_name = bag["type"]
    table = getattr(db, table_name)

    if table is None or not issubclass(table, (db.Base, db.CouchSync)):
        raise CbsException(TABLE_NOT_FOUND)

    if not is_admin():
        item_query = g.tran.query(table).filter_by(_deleted="infinity", _id=bag["_id"])
        item_query = item_query.first()
        if item_query is None:
            raise CbsException(USER_NO_ACCESS)

    pg_db = PostgresDatabase()
    _id, _rev = pg_db.remove(bag["_id"], bag["_rev"])
    return {"ok": True, "id": _id, "rev": _rev}


def listing(bag):
    table_name = bag["type"]
    table = getattr(db, table_name) if hasattr(db, table_name) else None

    if table is None or not issubclass(table, (db.Base, db.CouchSync)):
        raise CbsException(TABLE_NOT_FOUND)
    if table_name == "Organization" or table_name == "Position":
        query = g.tran.query()
    elif issubclass(table, db.Normal):
        query = g.tran.query(table.id).filter_by(_deleted='infinity')
    elif issubclass(table, db.CouchSync):
        query = g.tran.query(table._id).filter_by(_deleted='infinity')
    else:
        query = g.tran.query(table).filter_by(_deleted='infinity')

    doc_vars = vars(table)
    for var in doc_vars:
        if isinstance(doc_vars[var], InstrumentedAttribute):
            query = query.add_column(doc_vars[var])

    if table == db.Journal:
        if 'filter' in bag and 'date_start' in bag['filter']:
            query = query.filter(table.date >= bag["filter"]["date_start"])
            del bag["filter"]["date_start"]
        if 'filter' in bag and 'date_end' in bag['filter']:
            query = query.filter(bag["filter"]["date_end"] >= table.date)
            del bag["filter"]["date_end"]
        if 'filter' in bag and 'status' in bag['filter']:
            query = query.filter(bag["filter"]["status"] == table.status)
            del bag["filter"]["status"]
        if 'filter' in bag and 'userdoc_name' in bag['filter']:
            query = query.filter(table.client['name'].cast(TEXT).ilike(u"%{}%".format(bag["filter"]["userdoc_name"])))
            del bag["filter"]["userdoc_name"]
        if 'filter' in bag and 'number' in bag['filter']:
            query = query.filter(table.number == bag["filter"]["number"])
            del bag["filter"]["number"]
        if 'filter' in bag and 'user_id' in bag['filter']:
            query = query.filter(table.entry_user_id == bag["filter"]["user_id"])
            del bag["filter"]["user_id"]
        if 'filter' in bag and 'country_id' in bag['filter']:
            query = query.filter(table.country_id == bag["filter"]["country_id"])
            del bag["filter"]["country_id"]
        if 'filter' in bag and 'typeperson_id' in bag['filter']:
            query = query.filter(table.data.contains(type_coerce({"typeperson_id": bag["filter"]["typeperson_id"]}, JSONB)))
            del bag["filter"]["typeperson_id"]
        if 'filter' in bag and 'dtypes_id' in bag['filter']:
            query = query.filter(
                table.adocument.contains(type_coerce({"dtypes_id": bag["filter"]["dtypes_id"]}, JSONB)))
            del bag["filter"]["dtypes_id"]
    elif table == db.Menus:
        if not is_admin():
            menus_id = []
            roles = g.tran.query(db.Roles).filter_by(_deleted='infinity') \
                .filter(db.Roles._id.in_(g.user.roles_id if g.user.roles_id is not None else [])).all()
            for role in roles:
                menus_id.extend(role.menus_id)
            query = query.filter(db.Menus._id.in_(menus_id))
    elif table == db.Document:
        if 'filter' in bag and 'search' in bag['filter']:
            query = query.filter(or_(db.Document.title.ilike(u"%{}%".format(bag["filter"]["search"]))))
            del bag["filter"]["search"]
        if 'filter' in bag and 'organization_id' in bag['filter']:
            query = query.filter(db.Document.organization_id == bag["filter"]["organization_id"])
            del bag["filter"]["organization_id"]
        if 'filter' in bag and 'position_id' in bag['filter']:
            query = query.filter(db.Document.position_id == bag["filter"]["position_id"])
            del bag["filter"]["position_id"]
    elif table == db.Organizations:
        if 'search_ru' in bag:
            query = query.filter(table.name_ru.ilike(u"%{}%".format(bag["search_ru"])))
            del bag["search_ru"]
        if 'search_kg' in bag:
            query = query.filter(table.name_kg.ilike(u"%{}%".format(bag["search_kg"])))
            del bag["search_kg"]
        if 'search_inn' in bag:
            query = query.filter(table.inn.ilike(u"%{}%".format(bag["search_inn"])))
            del bag["search_inn"]
    elif table == db.Positions:
        if 'search' in bag:
            query = query.filter(table.name.ilike(u"%{}%".format(bag["search"])))
            del bag["search"]
    if "filter" in bag:
        if "data" in bag["filter"] and isinstance(bag["filter"]["data"], dict):
            query = query.filter(table.data.contains(type_coerce(bag["filter"]["data"], JSONB)))
            del bag["filter"]["data"]
        query = query.filter_by(**bag["filter"])

    if "order_by" in bag:
        query = query.order_by(*bag["order_by"])

    count = query.count()
    if "limit" in bag:
        query = query.limit(bag["limit"])
    if "offset" in bag:
        query = query.offset(bag["offset"])

    result = orm_to_json(query.all())

    if "with_related" in bag and bag["with_related"] == True:
        result = find_relations(result, table_name)

    return {"docs": result, "count": count}


def find_relations(row, related_table_name):
    if not isinstance(row, dict) and not isinstance(row, list):
        return row
    if isinstance(row, list):
        rel_column = []
        for r in row:
            rel_column.append(find_relations(r, related_table_name))
        return rel_column
    rel_column = {}
    if '_deleted' in row:
        del row['_deleted']
    for column in row:
        if re.match("[\w_]+_id", column) and (isinstance(row[column], basestring) or isinstance(row[column], int)):
            rel_table_name = ""
            up = True
            for char in column[:-3]:
                if up:
                    rel_table_name += char.upper()
                    up = False
                elif char != "_":
                    rel_table_name += char
                if char == "_":
                    up = True
            if rel_table_name == "Parent":
                related_table = getattr(db, related_table_name) if hasattr(db, related_table_name) else None
            elif rel_table_name == "EntryUser" or rel_table_name == "Executor":
                related_table = db.User
            else:
                related_table = getattr(db, rel_table_name) if hasattr(db, rel_table_name) else None
                if related_table is None:
                    rel_table_name_copy = rel_table_name[:-1] + 'ies' if \
                        rel_table_name.endswith('y') else rel_table_name + 'es'
                    related_table = getattr(db, rel_table_name_copy) if hasattr(db, rel_table_name_copy) else None
                if related_table is None:
                    rel_table_name_copy = rel_table_name + 's'
                    related_table = getattr(db, rel_table_name_copy) if hasattr(db, rel_table_name_copy) else None
            if related_table is not None:
                if issubclass(related_table, db.CouchSync):
                    rel_table_data = g.tran.query(related_table).filter_by(_deleted='infinity', _id=row[column])
                    rel_table_data = rel_table_data.first()
                else:
                    rel_table_data = g.tran.query(related_table).filter_by(id=row[column])
                    rel_table_data = rel_table_data.first()
                if rel_table_data is not None:
                    rel_table_data = orm_to_json(rel_table_data)
                    if issubclass(related_table, db.CouchSync):
                        del rel_table_data["_deleted"]
                    if 'password' in rel_table_data:
                        del rel_table_data['password']
                    if 'secure' in rel_table_data:
                        del rel_table_data['secure']
                    rel_column[column[:-3]] = rel_table_data
            rel_column[column] = row[column]
        elif isinstance(row[column], dict) or isinstance(row[column], list):
            if isinstance(row[column], list) and re.match("[\w_]+_id", column):
                rel_table_name = ""
                up = True
                for char in column[:-3]:
                    if up:
                        rel_table_name += char.upper()
                        up = False
                    elif char != "_":
                        rel_table_name += char
                    if char == "_":
                        up = True
                related_table = getattr(db, rel_table_name) if hasattr(db, rel_table_name) else None
                if related_table is not None:
                    rel_table_data = g.tran.query(related_table)
                    if issubclass(related_table, db.CouchSync):
                        rel_table_data = rel_table_data.filter_by(_deleted='infinity') \
                            .filter(related_table._id.in_(row[column]))
                    else:
                        rel_table_data = rel_table_data.filter(related_table.id.in_(row[column]))
                    rel_table_data = orm_to_json(rel_table_data.all())
                    for rel_table_data_item in rel_table_data:
                        if issubclass(related_table, db.CouchSync):
                            del rel_table_data_item["_deleted"]
                        if 'password' in rel_table_data_item:
                            del rel_table_data_item['password']
                        if 'secure' in rel_table_data_item:
                            del rel_table_data_item['secure']
                    rel_column[column[:-3]] = rel_table_data
            rel_column[column] = find_relations(row[column], related_table_name)
        else:
            if column == 'document_type':
                doc_types = document.all({})['doc_types']
                for doc_type in doc_types:
                    if doc_type['id'] == row[column]:
                        rel_column[str.format('{}_value', column)] = doc_type['name']
            elif isinstance(row[column], basestring):
                rel_enum = g.tran.query(db.Enums).filter_by(name=column) \
                    .filter(db.Enums.data.contains(type_coerce({"key": row[column]}, JSONB))).first()
                if rel_enum is not None:
                    rel_column[str.format('{}_value', column)] = rel_enum.data['name']
            rel_column[column] = row[column]
    return rel_column


def del_columns(data):
    cols_to_del = []
    for key in data:
        for key1 in data:
            if key[:-3] == key1 or str.format('{}_value', key) == key1:
                cols_to_del.append(key1)
    for col_to_del in cols_to_del:
        del data[col_to_del]
    for key in data:
        if isinstance(data[key], dict):
            del_columns(data[key])
