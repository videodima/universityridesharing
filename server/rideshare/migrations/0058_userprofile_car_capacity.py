# -*- coding: utf-8 -*-
# Generated by Django 1.11 on 2017-07-20 01:24
from __future__ import unicode_literals

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('rideshare', '0057_auto_20170719_0403'),
    ]

    operations = [
        migrations.AddField(
            model_name='userprofile',
            name='car_capacity',
            field=models.IntegerField(default=4),
            preserve_default=False,
        ),
    ]
