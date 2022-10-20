# coding: utf-8

"""
Test tasks.
"""

import law


class TestTask(law.Task):

    def output(self):
        return law.LocalFileTarget("$MLF_BASE/test_file.txt")

    def run(self):
        self.output().dump("some file content", formatter="text")
