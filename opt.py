
import argparse
import logging
import os
import sys
import numpy
import pickle

from datetime import datetime

import bluepyopt

import l5pc_evaluator

logger = logging.getLogger()

def create_optimizer(args):
    '''returns configured bluepyopt.optimisations.DEAPOptimisation'''
    from ipyparallel import Client
    rc = Client(profile=os.getenv('IPYTHON_PROFILE'))
    logger.debug('Using ipyparallel with %d engines', len(rc))
    lview = rc.load_balanced_view()

    def mapper(func, it):
        start_time = datetime.now()
        ret = lview.map_sync(func, it)
        logger.debug('Generation took %s', datetime.now() - start_time)
        return ret

    map_function = mapper
    evaluator = l5pc_evaluator.create()
    opt = bluepyopt.optimisations.DEAPOptimisation(
        evaluator=evaluator,
        map_function=map_function,
        seed=1,
        eta=1.,
        mutpb=1.,
        cxpb=1.)

    return opt


def get_parser():
    parser = argparse.ArgumentParser(
        formatter_class=argparse.RawDescriptionHelpFormatter,
        description='HP Tuning')
    parser.add_argument('--checkpoint', required=False, default=None,
                        help='Checkpoint pickle to avoid recalculation')
    parser.add_argument('--max_ngen', required=False, type=int, default=2,
                        help='Max number of generations to run')
    parser.add_argument('--offspring_size', required=False, type=int, default=4,
                        help='Offsprint size per generation')
    return parser


def main():
    """Main"""
    args = get_parser().parse_args()
    logging.basicConfig(level=logging.DEBUG,
                        stream=sys.stdout)

    opt = create_optimizer(args)
    opt.run(max_ngen=args.max_ngen,
            offspring_size=args.offspring_size,
            cp_filename=args.checkpoint,
            continue_cp=False)

if __name__ == '__main__':
    main()
