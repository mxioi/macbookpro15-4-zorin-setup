#!/bin/bash
# The shared helpers live in t2kit/lib/os.sh so the t2kit folder can be
# copied to a USB stick on its own. This keeps the scripts' old path working.
# shellcheck source=t2kit/lib/os.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../t2kit/lib/os.sh"
