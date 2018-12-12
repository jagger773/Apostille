# coding=utf-8
from flask import g

from app.service import table_access, chain

tables = [
    {
        'table': 'Organizations',
        'name': u'Организации',
        'role_requires': 0,
        'columns': [
            {'name': 'name_ru', 'displayName': u'Наименование Ru'},
            {'name': 'name_kg', 'displayName': u'Наименование Kg'},
            {'name': 'inn', 'displayName': u'Инн'}
        ]
    },
    {
        'table': 'Positions',
        'name': u'Должности',
        'role_requires': 0,
        'columns': [
            {'name': 'name', 'displayName': u'Наименование'}
        ]
    },
    {
        'table': 'Countries',
        'name': u'Страны',
        'role_requires': 0,
        'columns': [
            {'name': 'name', 'displayName': u'Название'},
            {'name': 'region', 'displayName': u'Регион'},
            {'name': 'data.name_eng', 'displayName': u'Название на англ'}
        ]
    },
    {
        'table': 'Enums',
        'name': u'Типы/Статусы',
        'role_requires': 0,
        'columns': [
            {'name': 'name', 'displayName': u'Тип'},
            {'name': 'data.name', 'displayName': u'Наименование'},
            {'name': 'data.key', 'displayName': u'Ключ'}
        ]
    },
    {
        'table': 'Dtypes',
        'name': u'Типы документов',
        'role_requires': 0,
        'columns': [
            {'name': 'name', 'displayName': u'Наименование'},
        ]
    },
    {
        'table': 'Typeperson',
        'name': u'Тип лица',
        'role_requires': 0,
        'columns': [
            {'name': 'name', 'displayName': u'Наименование'},
        ]
    },
    {
        'table': 'DirReportCategories',
        'name': u'Категории шаблонов',
        'role_requires': 10,
        'columns': [
            {'name': 'name', 'displayName': u'Наименование'},
            {'name': 'parent.name', 'displayName': u'Родитель'}
        ]
    },
    {
        'table': 'Roles',
        'list_only': True
    }
]


def tables_list(bag):
    ret = []
    for table in tables:
        if ('role_requires' not in table or g.user.role >= table['role_requires']) and \
                ('list_only' not in table or table['list_only'] is False):
            ret.append(table)
    return {'tables': tables}


def table_names(option):
    ret = []
    for table in tables:
        if option is not 'put' or 'list_only' not in table or table['list_only'] is False or \
                'role_requires' not in table or g.user.role >= table['role_requires']:
            ret.append(table['table'])
    return ret


@table_access(names=table_names('get'))
@chain(controller_name='data.get', output=['doc'])
def get(bag):
    pass


@table_access(names=table_names('listing'))
@chain(controller_name='data.listing', output=['docs', 'count'])
def listing(bag):
    pass


@table_access(names=table_names('put'))
@chain(controller_name='data.put', output=['id', 'rev'])
def save(bag):
    pass


@table_access(names=table_names('put'))
@chain(controller_name='data.remove', output=['id', 'rev'])
def remove(bag):
    pass

