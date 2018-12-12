# coding=utf-8
import json

from sqlalchemy import TypeDecorator, PickleType, Column, Numeric, Date, String, func, PrimaryKeyConstraint, types, ForeignKey, \
    DateTime, Integer, Enum, Float, Boolean
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.ext.declarative import declarative_base, declared_attr
from sqlalchemy.sql.functions import now

Base = declarative_base()


class Json(TypeDecorator):
    impl = JSONB

    def load_dialect_impl(self, dialect):
        if dialect.name == 'postgresql':
            return dialect.type_descriptor(JSONB())
        else:
            return dialect.type_descriptor(PickleType(pickler=json))

    def coerce_compared_value(self, op, value):
        return self.impl.coerce_compared_value(op, value)


class ABSTIME(types.UserDefinedType):
    def get_col_spec(self):
        return 'ABSTIME'

    def bind_processor(self, dialect):
        def process(value):
            return value

        return process

    def result_processor(self, dialect, coltype):
        def process(value):
            return value

        return process


class TableId(Base):
    __tablename__ = 'table_ids'
    seq = Column(Integer, primary_key=True)
    _id = Column(String, unique=True)
    table_name = Column(String, nullable=False)
    created = Column(DateTime, default=func.now())


class Normal(object):
    @declared_attr
    def __tablename__(cls):
        return cls.__name__.lower() + 's'

    id = Column(Integer, primary_key=True)


class User(Base, Normal):
    username = Column(String, unique=True, nullable=False)
    email = Column(String)
    password = Column(String, nullable=False)
    secure = Column(String, nullable=False)
    role = Column(Integer, nullable=False, default=0)
    rec_date = Column(DateTime, nullable=False, default=func.now())
    roles_id = Column(Json)
    status = Column(String)
    data = Column(Json)


class Token(Base, Normal):
    user_id = Column(Integer, ForeignKey(User.id, ondelete='no action', onupdate='cascade'), nullable=False)
    os = Column(String)
    imei = Column(String, nullable=False)
    token = Column(String, nullable=False)
    dat_rec = Column(DateTime, nullable=False, default=now())


class CouchSync(object):
    @declared_attr
    def __tablename__(cls):
        return cls.__name__.lower()

    @declared_attr
    def _id(cls):
        return Column(String, ForeignKey(TableId._id, onupdate='cascade', ondelete='cascade'), nullable=False)

    _created = Column(ABSTIME, nullable=False, default=func.now())
    _deleted = Column(ABSTIME, nullable=False, default='infinity')
    _rev = Column(String, nullable=False, default=0)

    @declared_attr
    def entry_user_id(cls):
        return Column(Integer, ForeignKey(User.id, ondelete='no action', onupdate='cascade'))

    @declared_attr
    def __table_args__(cls):
        return PrimaryKeyConstraint('_id', '_created', '_deleted'),


class Replicator(Base, CouchSync):
    history = Column(Json)
    last_seq = Column(Integer)
    replicator = Column(String)
    session_id = Column(String)
    version = Column(String)


class Design(Base, CouchSync):
    language = Column(String)
    views = Column(Json)


class UDF(Base, CouchSync):
    name = Column(String, nullable=False)
    udf_purpose = Column(Enum('operation', 'contractor', 'user', 'branch', 'approval', 'booking', name='udf_purposes'),
                         nullable=False)
    data = Column(Json, nullable=False)


class Roles(Base, CouchSync):
    name = Column(String, nullable=False)
    menus_id = Column(Json)
    data = Column(Json)


class Organizations(Base, CouchSync):
    name_ru = Column(String, nullable=False)
    name_kg = Column(String)
    inn = Column(String)


class Positions(Base, CouchSync):
    name = Column(String, nullable=True)
    data = Column(Json)


class Document(Base, CouchSync):
    title = Column(String)
    short_desc = Column(String)
    image = Column(Json)
    data = Column(Json)
    position_id = Column(String, nullable=False)
    organization_id = Column(String, nullable=False)


class DirReportCategories(Base, CouchSync):
    name = Column(String, nullable=False)
    parent_id = Column(String)


class DirReportTemplates(Base, CouchSync):
    code = Column(String, nullable=False)
    name = Column(String, nullable=False)
    template = Column(Json, nullable=False)
    report_category_id = Column(String, nullable=False)


class DirReportQueries(Base, CouchSync):
    code = Column(String, nullable=False)
    name = Column(String, nullable=False)
    query = Column(String, nullable=False)
    result_key = Column(String, nullable=False)


class Enums(Base, CouchSync):
    name = Column(String, nullable=False)
    data = Column(Json)


class Menus(Base, CouchSync):
    name = Column(String, nullable=False)
    parent_id = Column(String)
    data = Column(Json)


class Journal(Base, CouchSync):
    number = Column(String, nullable=False)
    status = Column(String, nullable=False)
    barcode = Column(Json)
    flag = Column(String)
    qrcode = Column(String)
    date = Column(Date, nullable=False)
    summ = Column(Integer, nullable=False)
    adocument = Column(Json)
    userdoc = Column(Json)
    empolyee = Column(Json)
    client = Column(Json)
    requisites = Column(Json)
    country_id = Column(String, nullable=False)
    data = Column(Json)


class Countries(Base, CouchSync):
    name = Column(String, nullable=False)
    region = Column(String)
    min_insurance = Column(Float)
    currency_id = Column(String)
    data = Column(Json, default={})


class Dtypes(Base, CouchSync):
    name = Column(String, nullable=False)
    data = Column(Json, default={})


class Typeperson(Base, CouchSync):
    name = Column(String, nullable=False)
    data = Column(Json, default={})



