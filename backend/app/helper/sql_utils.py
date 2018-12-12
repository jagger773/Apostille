# coding=utf-8
from flask import g
from sqlalchemy import text


def execute(sql=None, firstonly=False, params=None):
    result = []
    if sql:
        if firstonly:
            row = g.tran.execute(text(sql), params).first()
            if row:
                column = {}
                for col in row.items():
                    column[col[0]] = col[1]
                result.append(column)
        else:
            rows = g.tran.execute(text(sql), params).fetchall()
            for row in rows:
                column = {}
                for col in row.items():
                    column[col[0]] = col[1]
                result.append(column)
    return result

