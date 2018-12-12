# coding=utf-8
import re
from hashlib import sha1

import pyotp
from flask import g
from sqlalchemy import or_
from sqlalchemy import type_coerce
from sqlalchemy.dialects.postgresql import JSONB

from app import redis_session
from app.controller import entity
from app.keys import *
from app.messages import *
from app.model import db
from app.service import admin_required, table_access, chain
from app.service import is_admin
from app.utils import CbsException, orm_to_json

from app.keys import PASSWORD

# related company ids in mobile app
COMPANY_IDS = {
    'augarantid': '85c7c7cf-fd1d-4c10-88a3-8931f43c3784'
}


def register(bag):
    if 'data' not in bag:
        bag['data'] = {}
    bag['secure'] = pyotp.random_base32()
    bag[PASSWORD] = sha1(bag[PASSWORD] + bag['secure']).hexdigest()

    if not re.match('^[a-zA-Z]+[\w\-_]+$', bag[USERNAME]):
        raise CbsException(GENERIC_ERROR,
                           u'Имя пользователя может содержать только латинские буквы, цифры и знаки "-" и "_"!')

    user = g.tran.query(db.User).filter(or_(db.User.username == bag[USERNAME], db.User.email == bag[EMAIL])).first()
    if user:
        raise CbsException(USER_ALREADY_EXISTS)
    user = entity.add({CRUD: db.User, BOBJECT: bag})

    user_data = {
        ID: user.id,
        USERNAME: user.username,
        EMAIL: user.email,
        'role': user.role,
        'roles_id': user.roles_id,
        'rec_date': user.rec_date,
        'data': user.data
    }

    token = redis_session.open_session({'user_id': user.id})

    return {'token': token, 'user': user_data}


def put(bag):
    user = g.tran.query(db.User).filter_by(id=bag['id']).first()

    if user.username != bag['username']:
        if g.tran.query(db.User).filter_by(username=bag['username']).filter(db.User.id != user.id).count() > 0:
            raise CbsException(USER_ALREADY_EXISTS)
    if user.email != bag['email']:
        if g.tran.query(db.User).filter_by(email=bag['email']).filter(db.User.id != user.id).count() > 0:
            raise CbsException(USER_EMAIL_ALREADY_EXISTS)

    if 'password' in bag:
        password = sha1(bag[PASSWORD].encode('utf-8') + user.secure.encode('utf-8')).hexdigest()
        if bag[PASSWORD] != user.password and password != user.password and is_admin():
            user.password = password
        else:
            CbsException(USER_NO_ACCESS)

    user.username = bag['username']
    user.email = bag['email']
    user.data = bag['data']
    if 'roles_id' in bag:
        user.roles_id = bag['roles_id']

    user_data = {
        ID: user.id,
        USERNAME: user.username,
        EMAIL: user.email,
        'role': user.role,
        'roles_id': user.roles_id,
        'rec_date': user.rec_date,
        'data': user.data
    }
    return {'user': user_data}


def putUsername(bag):
    user = g.tran.query(db.User).filter(db.User.id != g.user.id, db.User.username == bag[USERNAME]).first()
    if user is not None:
        raise CbsException(GENERIC_ERROR, u'Такое имя пользователя уже есть')
    result = re.match('^[a-zA-Z]+[\w\-_]+$', bag[USERNAME])
    if not result:
        raise CbsException(GENERIC_ERROR,
                           u'Имя пользователя может содержать только латинские буквы, цифры и знаки "-" и "_"!')
    user = g.tran.query(db.User).filter_by(id=g.user.id).first()
    password = sha1(bag[PASSWORD].encode('utf-8') + user.secure.encode('utf-8')).hexdigest()
    if password == user.password:
        user.username = bag[USERNAME]
    else:
        raise CbsException(WRONG_PASSWORD)
        return

    user_data = {
        ID: user.id,
        USERNAME: user.username,
        EMAIL: user.email,
        'role': user.role,
        'rec_date': user.rec_date,
        'data': user.data
    }
    return {'user': user_data}


def putPassword(bag):
    user = g.tran.query(db.User).filter_by(id=g.user.id).first()
    password = sha1(bag[PASSWORD].encode('utf-8') + user.secure.encode('utf-8')).hexdigest()
    if password == user.password:
        user.password = sha1(bag["newpswd"] + user.secure).hexdigest()
    else:
        raise CbsException(WRONG_PASSWORD)
        return

    user_data = {
        ID: user.id,
        USERNAME: user.username,
        EMAIL: user.email,
        'role': user.role,
        'rec_date': user.rec_date,
        'data': user.data
    }
    return {'user': user_data}


def putEmail(bag):
    user = g.tran.query(db.User).filter(db.User.id != g.user.id, db.User.email == bag[EMAIL]).first()
    if user is not None:
        CbsException(GENERIC_ERROR, u'Такой E-mail уже есть')

    user = g.tran.query(db.User).filter_by(id=g.user.id).first()
    password = sha1(bag[PASSWORD].encode('utf-8') + user.secure.encode('utf-8')).hexdigest()
    if password == user.password:
        user.email = bag[EMAIL]
    else:
        raise CbsException(WRONG_PASSWORD)
        return

    user_data = {
        ID: user.id,
        USERNAME: user.username,
        EMAIL: user.email,
        'role': user.role,
        'rec_date': user.rec_date,
        'data': user.data
    }
    return {'user': user_data}


# def secure(bag):
#     user = g.tran.query(db.User).filter_by(id=bag.id).first()
#     password = sha1(bag[PASSWORD].encode('utf-8') + user.secure.encode('utf-8')).hexdigest()
#     if password == user.password:
#         user.password = sha1(bag["new_password"] + user.secure).hexdigest()
#     else:
#         raise CbsException(WRONG_PASSWORD)
#
#     user_data = {
#         ID: user.id,
#         USERNAME: user.username,
#         EMAIL: user.email,
#         'role': user.role,
#         'rec_date': user.rec_date,
#         'data': user.data
#     }
#     return {'user': user_data}


def auth(bag):
    user = g.tran.query(db.User).filter(db.User.username == bag[USERNAME]).first()
    if not user:
        raise CbsException(USER_NOT_FOUND)
    password = sha1(bag[PASSWORD].encode('utf-8') + user.secure.encode('utf-8')).hexdigest()
    if user.password != password:
        raise CbsException(WRONG_PASSWORD)

    user_data = {
        ID: user.id,
        USERNAME: user.username,
        EMAIL: user.email,
        'role': user.role,
        'roles_id': user.roles_id,
        'rec_date': user.rec_date,
        'data': user.data
    }

    token = redis_session.open_session({'user_id': user.id})

    return {'token': token, 'user': user_data}


@admin_required()
def listing(bag):
    return {'users': orm_to_json(g.tran.query(db.User).all())}
