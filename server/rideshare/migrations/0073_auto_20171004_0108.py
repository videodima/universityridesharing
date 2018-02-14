# -*- coding: utf-8 -*-
# Generated by Django 1.11 on 2017-10-04 01:08
from __future__ import unicode_literals

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('rideshare', '0072_auto_20171004_0107'),
    ]

    operations = [
        migrations.AddField(
            model_name='userprofile',
            name='destination_location',
            field=models.CharField(blank=True, max_length=200, null=True),
        ),
        migrations.AddField(
            model_name='userprofile',
            name='user_approved',
            field=models.BooleanField(default=False),
        ),
    ]
