#!/usr/bin/env gnatpython

"""test utils

This module is imported by all testcase. It parse the command lines options
and provide some usefull functions.

You should never call this module directly. To run a single testcase, use
 ./testsuite.py NAME_OF_TESTCASE
"""

from gnatpython.env import Env
from gnatpython.ex import Run, STDOUT
from gnatpython.expect import ExpectProcess
from gnatpython.fileutils import mkdir
from gnatpython.main import Main

import os
import re

POLYORB_CONF = "POLYORB_CONF"

EXE_EXT = Env().target.os.exeext

def assert_exists(filename):
    """Assert that the given filename exists"""
    assert os.path.exists(filename), "%s not found" % filename

def client_server(client_cmd, client_conf, server_cmd, server_conf):
    """Run a client server testcase

    Run server_cmd and extract the IOR string.
    Run client_cmd with the server IOR string
    Check for "END TESTS................   PASSED"
    if found return True
    """
    print "Running client %s (config=%s)\nserver %s (config=%s)" % (
        client_cmd, client_conf, server_cmd, server_conf)
    client = os.path.join(BASE_DIR, client_cmd + EXE_EXT)
    server = os.path.join(BASE_DIR, server_cmd + EXE_EXT)

    # Check that files exist
    assert_exists(client)
    assert_exists(server)

    if server_conf:
        server_polyorb_conf = os.path.join(options.testsuite_src_dir,
                                           server_conf)
        assert_exists(server_polyorb_conf)
    else:
        server_polyorb_conf = ""

    os.environ[POLYORB_CONF] = server_polyorb_conf

    # Run the server command and retrieve the IOR string
    server_handle = ExpectProcess(make_run_cmd([server],options.coverage))

    try:
        result = server_handle.expect([r"IOR:([a-z0-9]+)['|\n\r]"], 10)
        if result != 0:
            print "Expect error cannot find IOR when running %s" % server
            server_handle.close()
            return False

        IOR_str = server_handle.out()[1]

        # Run the client with the IOR argument
        mkdir(os.path.dirname(options.out_file))

        if client_conf:
            client_polyorb_conf = os.path.join(options.testsuite_src_dir,
                                               client_conf)
            assert_exists(client_polyorb_conf)
        else:
            client_polyorb_conf = ''

        if client_polyorb_conf != server_polyorb_conf:
            client_env = os.environ.copy()
            client_env[POLYORB_CONF] = client_polyorb_conf
        else:
            client_env = None

        Run(make_run_cmd([client, IOR_str],options.coverage),
            output=options.out_file + 'server', error=STDOUT,
            timeout=options.timeout, env=client_env)

        # Kill the server process
        server_handle.close()
        for elmt in [client, server]:
            run_coverage_analysis(elmt)

    except Exception, e:
        # Be sure that the server handle is properly closed
        print e
        server_handle.close()

    return _check_output(options.out_file + 'server')

def local(cmd, config_file, args=None):
    """Run a local test

    Execute the given command.
    Check for "END TESTS................   PASSED"
    if found return True

    PARAMETERS:
        cmd: the command to execute
        config_file: to set POLYORB_CONF
        args: list of additional parameters
    """
    args = args or []
    print "Running %s %s (config=%s)" % (cmd, " ".join(args), config_file)
    if config_file:
        config_file = os.path.join(options.testsuite_src_dir, config_file)
        assert_exists(config_file)
    os.environ[POLYORB_CONF] = config_file

    mkdir(os.path.dirname(options.out_file))
    command = os.path.join(BASE_DIR, cmd + EXE_EXT)
    assert_exists(command)
    Run(make_run_cmd([command] + args, options.coverage),
        output=options.out_file + 'local', error=STDOUT,
        timeout=options.timeout)
    if options.coverage=="True":
        run_coverage_analysis(command)
    return _check_output(options.out_file + 'local')


def _check_output(output_file):
    """Check that END TESTS....... PASSED is contained in the output"""
    if os.path.exists(output_file):
        test_outfile = open(output_file)
        test_out = test_outfile.read()
        test_outfile.close()

        if re.search(r"END TESTS.*PASSED", test_out):
            return True
        else:
            print test_out
            return False

def parse_cmd_line():
    """Parse command line

    Returns options object
    """
    main = Main(require_docstring=False, add_targets_options=True)
    main.add_option('--timeout', dest='timeout', type=int,
                    default=None)
    main.add_option('--build-dir', dest="build_dir")
    main.add_option('--testsuite-src-dir', dest='testsuite_src_dir')
    main.add_option('--out-file', dest="out_file")
    main.add_option('--coverage', dest="coverage", default=False)
    main.parse_args()
    return main.options

def make_run_cmd(cmd, coverage="False"):
    """Create a command line for Run in function of coverage

    Returns command and arguments list
    """
    L = []
    if coverage=="True":
        L.extend(['xcov', '--run', '--target=i386-linux', '-o',
                  cmd[0] + '.trace', cmd[0]])
        if len(cmd)>1:
            L.append('-eargs')
            L.extend(cmd[1:])
    else:
        L.extend(cmd);
    return L

def run_coverage_analysis(command):
    """Run xcov with appropriate arguments to retrieve coverage information

    Returns an object of type run
    """
    return Run(['xcov', '--coverage=branch', '--annotate=report',
                command + ".trace"],
               output=options.out_file + '.trace', error=STDOUT,
               timeout=options.timeout)

# Parse command lines options
options  = parse_cmd_line()

# All executable tests path are relative to PolyORB testsuite dir
BASE_DIR = os.path.join(options.build_dir, 'testsuite')
