# coding: utf-8

"""
External tasks.
"""

import law

from mlforge.tasks.base import DatasetTask


class ProvideData(DatasetTask, law.ExternalTask):

    def output(self):
        return law.LocalFileTarget(
            f"{self.config_inst.data_path}/{self.config_inst.year}__{self.dataset}/data_resolved_0.root",
        )


class Preprocessing(DatasetTask):

    def requires(self):
        return ProvideData.req(self)

    def output(self):
        return self.local_target("test.txt")

    def run(self):
        self.output().dump("hallo", formatter="text")


class Splitting(DatasetTask):

    def requires(self):
        return Preprocessing.req(self)

    def output(self):
        return self.local_target("test.txt")

    def run(self):
        self.output().dump("hallo", formatter="text")
