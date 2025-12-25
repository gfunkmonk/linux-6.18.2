// SPDX-License-Identifier: GPL-2.0
#ifndef CONFIG_SCHED_MUQSS
#define COMPILE_OFFSETS
#include <linux/kbuild.h>
#include <linux/types.h>
#include "sched.h"

int main(void)
{
	DEFINE(RQ_nr_pinned, offsetof(struct rq, nr_pinned));

	return 0;
}
#else
/* MuQSS doesn't need rq-offsets */
int main(void)
{
	return 0;
}
#endif
