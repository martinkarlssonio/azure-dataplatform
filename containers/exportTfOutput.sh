outputJson=$(terraform output -json | jq .)
echo ${outputJson}

#Export ResourceGroup details
TF_VAR_raw_ctgrp_name=$(echo ${outputJson} | jq .raw_ctgrp_name.value)
export TF_VAR_raw_ctgrp_name=$(echo ${TF_VAR_raw_ctgrp_name//'"'})

TF_VAR_enriched_ctgrp_name=$(echo ${outputJson} | jq .enriched_ctgrp_name.value)
export TF_VAR_enriched_ctgrp_name=$(echo ${TF_VAR_enriched_ctgrp_name//'"'})

TF_VAR_curated_ctgrp_name=$(echo ${outputJson} | jq .curated_ctgrp_name.value)
export TF_VAR_curated_ctgrp_name=$(echo ${TF_VAR_curated_ctgrp_name//'"'})