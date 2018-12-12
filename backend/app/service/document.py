# coding=utf-8
from flask import g
from sqlalchemy import or_, type_coerce
from sqlalchemy.dialects.postgresql import JSONB
from datetime import datetime

from app.keys import *
from app.messages import *
from app.model import db
from app.service import table_access, chain
from app.utils import CbsException, orm_to_json
import os
from run import app


@table_access(name=db.Document.__name__)
@chain(controller_name='data.put', output=['id', 'rev'])
def save(bag):
    pass


@table_access(name=db.Document.__name__)
@chain(controller_name='data.listing', output=['docs', 'count'])
def list(bag):
    pass


@table_access(name=db.Document.__name__)
@chain(controller_name='data.get', output=['doc'])
def get(bag):
    pass


@table_access(name=db.Document.__name__)
@chain(controller_name='data.delete', output=['ok'])
def delete(bag):
    pass


def return_count_doc(bag):
    query = g.tran.query(db.Document).filter_by(_deleted='infinity', document_type='forum', document_status='approved') \
        .filter(or_(db.Document.data.contains(type_coerce({'sections_id': bag['search']}, JSONB)))).order_by(
        '_created desc')
    count = query.count()

    return {"count": count}


def find_document(bag):
    query = g.tran.query(db.Document).filter_by(_deleted='infinity') \
        .filter(or_(db.Document.title.ilike(u"%{}%".format(bag['search'])))).order_by('_created desc')
    query = query.limit(5)
    count = query.count()
    result = orm_to_json(query.all())

    return {'docs': result, "count": count}


def find_all(bag):
    query = g.tran.query(db.Document).filter_by(_deleted='infinity', document_type='forum', document_status='approved') \
        .filter(or_(db.Document.title.ilike(u"%{}%".format(bag['search'])),
                    db.Document.short_desc.ilike(u"%{}%".format(bag['search'])),
                    db.Document.data.contains(type_coerce({'text': bag['search']}, JSONB)))).order_by('_created desc')
    count = query.count()
    result = orm_to_json(query.all())

    return {'docs': result, "count": count}


def delete_image(bag):
    query = g.tran.query(db.Document).filter_by(_id=u"{}".format(bag['id']))
    doc = query.one()
    file_name = bag['name']
    files = doc.data['files']
    for i in range(len(files)):
        if files[i]['filename'] == file_name:
            del files[i]
            query.update({"data": doc.data})
            file_path = os.path.join(app.config['UPLOADED_DEFAULTS_DEST'], file_name)
            os.remove(file_path)
            break
    return {'ok': True}


def remove_image(bag):
    file_path = os.path.join(app.config['UPLOADED_DEFAULTS_DEST'], bag['filename'])
    os.remove(file_path)
    return {'ok': True}
