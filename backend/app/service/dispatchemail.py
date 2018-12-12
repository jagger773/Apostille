# coding: utf-8

import smtplib
#! /usr/bin/python

from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from app.messages import *
from email.mime.text import MIMEText
from app.utils import CbsException


def send_email(bag):
    me = 'info@tor.kg'
    you = bag['email']
    html = "Добро пожаловать на форум\nВаш логин:{0}\nпароль: {1}\n вы можете пройти по следующей ссылку: http://tor.kg/".format(bag['login'], bag['password']or "")
    subj = 'Регистрация в форуме'

    server = "smtp.tor.kg"
    port = 25
    user_name = "info@tor.kg"
    user_passwd = "torkgadmin312"

    msg = MIMEText(html, "html", "utf-8")
    msg['Subject'] = subj
    msg['From'] = me
    msg['To'] = you

    s = smtplib.SMTP(server, port)
    s.ehlo()
    s.starttls()
    s.ehlo()
    s.login(user_name, user_passwd)
    s.sendmail(me, you, msg.as_string())
    s.quit()
    return
