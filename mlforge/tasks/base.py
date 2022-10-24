# coding: utf-8

"""
Base tasks.
"""

import os

import luigi
import law


class BaseTask(law.Task):

    version = luigi.Parameter()

    def store_parts(self):
        parts = law.util.InsertableDict()

        # in this base class, just add the task class name
        parts["task_family"] = self.task_family

        # add the version when set
        if self.version is not None:
            parts["version"] = self.version

        return parts

    def local_path(self, *path, **kwargs):
        # concatenate all parts that make up the path and join them
        parts = tuple(self.store_parts().values()) + path
        path = os.path.join(*map(str, parts))

        return path

    def local_target(self, *path, **kwargs):
        _dir = kwargs.pop("dir", False)
        fs = kwargs.setdefault("fs", "local_store_fs")

        # select the target class
        cls = law.LocalDirectoryTarget if _dir else law.LocalFileTarget

        # create the local path
        path = self.local_path(*path, fs=fs)

        # create the target instance and return it
        return cls(path, **kwargs)


class ConfigTask(BaseTask):

    config = luigi.Parameter(default="config_2018")

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)

        if self.config == "config_2018":
            from mlforge.config.config_2018 import config
            self.config_inst = config
        else:
            raise ValueError(f"unknown config '{self.config}'")

    def store_parts(self):
        parts = super().store_parts()

        parts.insert_after("task_family", "config", self.config_inst.name)

        return parts


class DatasetTask(ConfigTask):

    dataset = luigi.Parameter(default="hh_ggf_kl1_kt1")

    def store_parts(self):
        parts = super().store_parts()

        parts.insert_after("config", "dataset", self.dataset)

        return parts
