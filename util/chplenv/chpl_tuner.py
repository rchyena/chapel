#!/usr/bin/env python
import optparse
import overrides
from sys import stdout, stderr
from utils import error, memoize

valid_tuners = set(['none'])

@memoize
def get():
    tuner_val = overrides.get('CHPL_TUNER')
    if not tuner_val:
        tuner_val = 'none'
    elif tuner_val not in valid_tuners:
        stderr.write('Warning: Invalid tuner value "{0}"\n'.format(tuner_val))
        tuner_val = 'none'
    return tuner_val

def _main():
    parser = optparse.OptionParser()
    parser.add_option('-l', '--list', dest='list', action='store_true',
                      default=False, help='display the list of valid tuners')
    (options, args) = parser.parse_args()

    if options.list:
        stdout.write("Valid tuners: {0}\n".format(", ".join(valid_tuners)))
    else:
        tuner_val = get()
        error("{0}\n".format(tuner_val), ValueError)


if __name__ == '__main__':
    _main()
