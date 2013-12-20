#!/bin/bash -x
q="${*:?}"
dig +short txt ${q// /_}.wp.dg.cx
