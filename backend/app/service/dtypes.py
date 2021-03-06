from flask import g
from sqlalchemy import or_, type_coerce
from sqlalchemy.dialects.postgresql import JSONB
from datetime import datetime

from app.keys import *
from app.messages import *
from app.model import db
from app.service import table_access, chain
from app.utils import CbsException, orm_to_json


@table_access(name=db.Dtypes.__name__)
@chain(controller_name='data.listing', output=['docs', 'count'])
def list(bag):
    pass


@table_access(name=db.Dtypes.__name__)
@chain(controller_name='data.get', output=['doc'])
def get(bag):
    pass


@table_access(name=db.Dtypes.__name__)
@chain(controller_name='data.put', output=['id', 'rev'])
def save(bag):
    pass
