# vcs flow for the sram uvc
# usage: make            build + run the regression with coverage
#        make TEST=sram_ecc_test
#        make cov        open the coverage gui

TEST ?= sram_regression_test
SEED ?= 1

COMP = vcs -full64 -sverilog -ntb_opts uvm-ieee \
       -timescale=1ns/1ps -debug_access+all \
       -cm line+cond+fsm+tgl+branch+assert \
       -f filelist.f -l comp.log

RUN  = ./simv +UVM_TESTNAME=$(TEST) +ntb_random_seed=$(SEED) \
       -cm line+cond+fsm+tgl+branch+assert \
       -cm_name $(TEST) -l $(TEST).log

all: comp run

comp:
	$(COMP)

run:
	$(RUN)

cov:
	dve -full64 -cov -dir simv.vdb &

clean:
	rm -rf simv* csrc *.log *.vdb ucli.key DVEfiles AN.DB vc_hdrs.h
