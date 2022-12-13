# coding: utf-8

"""
External tasks.
"""

import law
import os
import luigi

from mlforge.tasks.base import DatasetTask
from columnflow.util import dev_sandbox, maybe_import
from columnflow.columnar_util import sorted_ak_to_parquet

pyarrow= maybe_import("pyarrow")
pq = maybe_import("pyarrow.parquet")
np = maybe_import("numpy")
uproot = maybe_import("uproot")
ak = maybe_import("awkward")
from . import hh_helpers


class ProvideData(DatasetTask, law.ExternalTask):

    branch = luigi.Parameter(default=0)

    def inputs(self):
        self.file_name = self.create_branch_map()[self.branch]

    def output(self):
        # from IPython import embed
        # embed()
        return law.LocalFileTarget(
            # f"{self.config_inst.data_path}/{self.config_inst.year}__{self.dataset}/{super().create_branch_map[self.branch]}",
            f"/afs/desy.de/user/s/schaefes/xxl/hh_data/{self.dataset}_ext_eval_set/{super().create_branch_map()[self.branch]}",
        )


class Preprocessing(DatasetTask):

    sandbox = dev_sandbox("bash::$MLF_BASE/sandboxes/venv_preprocessing.sh")
    branch = ProvideData.branch

    # def __init__(self, *args, **kwargs):
    #     #from IPython import embed; embed()
    #     self.version = kwargs.get("version")
    #     self.config = kwargs.get("config")
    #     super().__init__()
    #     self.file_name = self.create_branch_map()[self.branch]

    def requires(self):
        return ProvideData.req(self, branch=self.branch)

    def output(self):
        return self.local_target(f"{self.dataset}_{self.branch}.parquet")

    def run(self):
        rec = np.load(self.input().path)['events']
        field_names = rec.dtype.names
        self.local_target()
        ndarray_table = ak.from_arrow(pyarrow.table(
            {
            f"{name}": rec[f"{name}"] for name in field_names
            }
        ))

        with self.output().localize("w") as outp:
            from IPython import embed; embed()

            sorted_ak_to_parquet(ndarray_table, outp.path)


class Splitting(DatasetTask):

    def requires(self):
        return Preprocessing.req(self)

    def output(self):
        return self.local_target("test.txt")

    def run(self):
        self.output().dump("hallo", formatter="text")
