# -*- coding: utf-8 -*-
# Generated by Django 1.11 on 2017-09-17 09:51
from __future__ import unicode_literals

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('rideshare', '0063_auto_20170917_0930'),
    ]

    operations = [
        migrations.AddField(
            model_name='userprofile',
            name='safety_score',
            field=models.IntegerField(default=5),
        ),
    ]
