SD = scripts
FD = figures
CD = .cache
CMD = R CMD BATCH --no-save
OUTPUTS = $(FD)/corr.pdf $(FD)/interaction_mixed.pdf $(FD)/interaction_all.pdf $(CD)/res_all.rda $(FD)/movement-map.pdf

all: $(OUTPUTS)

clean:
	-rm *.Rout
	-rm .cache/*
	-rm figures/*

$(FD)/interaction_mixed.pdf: $(SD)/19-vis-urban.R $(CD)/i_res_v2.rda
	$(CMD) $(SD)/19-vis-urban.R

$(FD)/interaction_all.pdf: $(SD)/18-vis-year.R $(CD)/i_res_all.rda
	$(CMD) $(SD)/18-vis-year.R

$(CD)/i_res_v2.rda: $(SD)/17-regression-3-urban.R $(CD)/napp_ana.rda
	$(CMD) $(SD)/17-regression-3-urban.R

$(CD)/i_res_all.rda: $(SD)/16-regression-2-year.R $(CD)/napp_ana.rda
	$(CMD) $(SD)/16-regression-2-year.R

$(CD)/res_all.rda: $(SD)/15-regression-1.R $(CD)/napp_ana.rda
	$(CMD) $(SD)/15-regression-1.R

$(FD)/movement-map.pdf: $(SD)/14-movement-map.R $(CD)/napp_dat.rda
	$(CMD) $(SD)/14-movement-map.R

$(FD)/corr.pdf: $(SD)/13-correlation.R
	$(CMD) $(SD)/13-correlation.R

$(CD)/napp_ana.rda: $(SD)/12-make-variables.R $(CD)/napp_dat.rda
	$(CMD) $(SD)/12-make-variables.R

$(CD)/napp_dat.rda: $(SD)/11-make-analysis-data.R $(CD)/pop_density.rda $(CD)/teachers.rda $(CD)/move_by_napp.rda $(CD)/parse_lookup.rda
	$(CMD) $(SD)/11-make-analysis-data.R

$(CD)/parse_lookup.rda: $(SD)/10-unit-id.R $(CD)/napp_to_nad.rda
	$(CMD) $(SD)/10-unit-id.R

$(CD)/pop_density.rda: $(SD)/09-pop-density.R $(SD)/05-create-temp-map.R
	$(CMD) $(SD)/09-pop-density.R

$(CD)/teachers.rda: $(SD)/08-teachers-var.R $(CD)/napp_to_nad.rda
	$(CMD) $(SD)/08-teachers-var.R

$(CD)/move_by_napp.rda: $(SD)/07-move-napp-agg.R $(SD)/05-create-temp-map.R $(SD)/06-make-sql-roll-movem.R
	$(CMD) $(SD)/06-make-sql-roll-movem.R
	$(CMD) $(SD)/07-move-napp-agg.R

$(SD)/05-create-temp-map.R: $(SD)/03-make-napp-lookup.R $(SD)/04-make-nad-map.R
	$(CMD) $(SD)/04-make-nad-map.R
	$(CMD) $(SD)/05-create-temp-map.R
	touch $(SD)/05-create-temp-map.R

# make napp_to_newid and nad_to_newid
$(SD)/03-make-napp-lookup.R: $(CD)/napp_to_nad.rda
	$(CMD) $(SD)/03-make-napp-lookup.R
	touch $(SD)/03-make-napp-lookup.R

$(CD)/napp_to_nad.rda: $(SD)/01-make-napp-sql.R $(SD)/02-napp-to-nad.R
	$(CMD) $(SD)/01-make-napp-sql.R
	$(CMD) $(SD)/02-napp-to-nad.R
