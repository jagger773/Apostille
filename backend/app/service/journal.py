# coding=utf-8
from flask import g
from sqlalchemy import or_, type_coerce, func
from sqlalchemy.dialects.postgresql import JSONB
from datetime import datetime

from app import controller
from app.keys import *
from app.messages import *
from app.model import db
from app.service import table_access, chain, is_admin
from app.utils import CbsException, orm_to_json
import os
from run import app
from dateutil.parser import parse
from random import choice
from string import digits




@table_access(name=db.Journal.__name__)
@chain(controller_name='data.put', output=['id', 'rev'])
def save_list(bag):
    pass


@table_access(name=db.Journal.__name__)
@chain(controller_name='data.listing', output=['docs', 'count'])
def listing(bag):
    pass


@table_access(name=db.Journal.__name__)
@chain(controller_name='data.get', output=['doc'])
def get(bag):
    pass


@table_access(name=db.Journal.__name__)
@chain(controller_name='data.delete', output=['ok'])
def delete(bag):
    pass


@table_access('Journal')
def save(bag):
    country = g.tran.query(db.Countries.name).filter_by(_deleted='infinity')\
        .filter(db.Countries._id == bag['country_id']).first()
    country = orm_to_json(country)
    dateperiod = parse(bag['date'])
    month = str(dateperiod.month)
    years = str(dateperiod.year)
    day = str(dateperiod.day)
    period_querter = years + '-'+month + '-'+day
    stt = g.redis.incr("APOSTILLE")
    bag['number'] = str(stt).zfill(5)
    bag['barcode'] = (''.join(choice(digits) for i in range(12)))
    bag['qrcode'] = "Номер:{0}\nДата проставления апостиля: {1}\nСтрана, в которой будет предъявлен документ:{2}"\
        .format(bag['number'], period_querter, country or "")
    temp_result = controller.call(controller_name='data.put', bag=bag)
    return {'resultList': temp_result}


def dashboard(bag):
    query = g.tran.query(db.Journal) \
        .filter_by(_deleted='infinity')

    if 'status' in bag:
        query = query.filter(db.Journal.status == bag['status'])

    if 'date_start' in bag:
        query = query.filter(db.Journal.date >= bag['date_start'])

    if 'date_end' in bag:
        query = query.filter(db.Journal.date <= bag['date_end'])

    incoming_query = query.filter_by(status='Входящий')
    outgoing_query = query.filter_by(status='Исходящий')
    spoiled_query = query.filter_by(status='испорчен')
    refused_query = query.filter_by(status='Отказано')

    incoming = orm_to_json(incoming_query.all())
    incoming_sum = 0
    incoming_count = incoming.__len__()
    for inc in incoming:
        incoming_sum += inc['summ']
    outgoing = orm_to_json(outgoing_query.all())
    outgoing_sum = 0
    outgoing_count = outgoing.__len__()
    for out in outgoing:
        outgoing_sum += out['summ']
    spoiled = orm_to_json(spoiled_query.all())
    spoiled_sum = 0
    spoiled_count = spoiled.__len__()
    for inc in spoiled:
        spoiled_sum += inc['summ']
    refused = orm_to_json(refused_query.all())
    refused_sum = 0
    refused_count = refused.__len__()
    for ref in refused:
        refused_sum += ref['summ']

    return {'data': {
        'incoming': incoming_sum,
        'incoming_count': incoming_count,
        'outgoing': outgoing_sum,
        'outgoing_count': outgoing_count,
        'spoiled': spoiled_sum,
        'spoiled_count': spoiled_count,
        'refused': refused_sum,
        'refused_count': refused_count
    }}
