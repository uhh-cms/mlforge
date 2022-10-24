# coding: utf-8

"""
2018 test config.
"""

from law.util import DotDict


config = DotDict.wrap({
    "name": "config_2018",

    "year": 2018,

    "data_path": "/nfs/dust/cms/user/riegerma/hh_data/bbtt3",

    "datasets": [
        "hh_ggf_kl1_kt1",
        "tth_bb",
    ],
})
