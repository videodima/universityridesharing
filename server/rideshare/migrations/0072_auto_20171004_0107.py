# -*- coding: utf-8 -*-
# Generated by Django 1.11 on 2017-10-04 01:07
from __future__ import unicode_literals

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('rideshare', '0071_userprofile_destination_location'),
    ]

    operations = [
        migrations.RemoveField(
            model_name='userprofile',
            name='destination_location',
        ),
        migrations.RemoveField(
            model_name='userprofile',
            name='user_approved',
        ),
        migrations.AddField(
            model_name='userprofile',
            name='notification',
            field=models.BooleanField(default=False),
        ),
    ]
