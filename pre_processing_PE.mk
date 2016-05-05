NAME?=NO_NAME
r1?=NO_R1
r2?=NO_R2

CLEAN_SOLEXA=clean_solexa_hiseq.pl
FASTUNIQ=/opt/paulo/mestrado/softwares/FastUniq/source/fastuniq
TRIM_GALORE=/opt/paulo/mestrado/softwares/trim_galore/trim_galore

path=$(PWD)

folder01=$(path)/01-clean_solexa
folder02=$(path)/02-fastuniq
folder03=$(path)/03-trim_galore

all: $(folder03)/$(NAME)_R1_trim_galore.fq $(folder03)/$(NAME)_R2_trim_galore.fq

$(folder01)/$(NAME).paired: $(path)/$(r1) $(path)/$(r2)
	@echo ------Starting to process the reads------
	@date
	@mkdir $(folder01)
	cd $(folder01); $(CLEAN_SOLEXA) -1 $(path)/$(r1) -2 $(path)/$(r2) -q 20 -p $(NAME)

#$(folder01)/$(NAME)_R1_clean_solexa: $(folder01)/$(NAME).paired
#	@grep -A 3 "1:N:0" $^ | sed '/^--$$/d' > $@

#$(folder01)/$(NAME)_R2_clean_solexa: $(folder01)/$(NAME).paired
#	@grep -A 3 "2:N:0" $^ | sed '/^--$$/d' > $@

$(folder01)/$(NAME)_R1_clean_solexa $(folder01)/$(NAME)_R2_clean_solexa: $(folder01)/$(NAME).paired
	python scripts/separate_pe.py $^ $(folder01)/$(NAME)_R1_clean_solexa $(folder01)/$(NAME)_R2_clean_solexa

$(folder02)/$(NAME)_input_list: $(folder01)/$(NAME)_R1_clean_solexa $(folder01)/$(NAME)_R2_clean_solexa
	@mkdir $(folder02)
	cd $(folder02)
	@echo $(folder01)/$(NAME)_R1_clean_solexa > $@
	@echo $(folder01)/$(NAME)_R2_clean_solexa >> $@

$(folder02)/$(NAME)_R1_fastuniq $(folder02)/$(NAME)_R2_fastuniq: $(folder02)/$(NAME)_input_list
	$(FASTUNIQ) -i $^ -t q -o $(folder02)/$(NAME)_R1_fastuniq -p $(folder02)/$(NAME)_R2_fastuniq -c 0

$(folder03)/$(NAME)_R1_trim_galore.fq $(folder03)/$(NAME)_R2_trim_galore.fq: $(folder02)/$(NAME)_R1_fastuniq $(folder02)/$(NAME)_R2_fastuniq
	@mkdir $(folder03)
	cd $(folder03); $(TRIM_GALORE) --retain_unpaired --paired --dont_gzip $^
	@mv $(folder03)/$(NAME)_R1_fastuniq_val_1.fq $(folder03)/$(NAME)_R1_trim_galore.fq
	@mv $(folder03)/$(NAME)_R2_fastuniq_val_2.fq $(folder03)/$(NAME)_R2_trim_galore.fq
	@date
	@echo ------Finished------
clean:
	rm -r $(folder01) $(folder02)
