from __future__ import annotations

import os
import pathlib
from functools import cached_property
from typing import Protocol

from platformdirs import PlatformDirs


class PlatformDirsProto(Protocol):
    @property
    def user_config_path(self) -> pathlib.Path: ...


def _resolve_platform_dirs() -> PlatformDirsProto:
    """Decide on what PlatformDirs class to use.

    In case a folder exists (which can be customized with the environmental
    variable `SNOWFLAKE_HOME`) we use that directory as all platform
    directories. If this folder does not exist we'll fall back to platformdirs
    defaults.

    This helper function was introduced to make this code testable.
    """
    platformdir_kwargs = {
        "appname": "snowflake",
        "appauthor": False,
    }
    snowflake_home = pathlib.Path(
        os.environ.get("SNOWFLAKE_HOME", "~/.snowflake/"),
    ).expanduser()
    if snowflake_home.exists():
        return SFPlatformDirs(
            str(snowflake_home),
            **platformdir_kwargs,
        )
    else:
        # In case SNOWFLAKE_HOME does not exist we fall back to using
        # platformdirs to determine where system files should be placed. Please
        # see docs for all the directories defined in the module at
        # https://platformdirs.readthedocs.io/
        return PlatformDirs(**platformdir_kwargs)


res = _resolve_platform_dirs()
print(res.user_config_path)