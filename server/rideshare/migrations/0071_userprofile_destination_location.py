# -*- coding: utf-8 -*-
# Generated by Django 1.11 on 2017-09-28 00:34
from __future__ import unicode_literals

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('rideshare', '0070_userprofile_user_approved'),
    ]

    operations = [
        migrations.AddField(
            model_name='userprofile',
            name='destination_location',
            field=models.CharField(blank=True, max_length=300, null=True),
        ),
    ]
