{% set var_model_types = var('model_types') %}
{% set suffix_model_type = '_prefixes' %}

{% set vars_prefix = [] %}

{% for model_type in var_model_types %}
  {% do vars_prefix.append(model_type ~ suffix_model_type) %}
{% endfor %}

with vars_prefix_table as (
    {{ loop_vars(vars_prefix) }}
)

select
    var_name as prefix_name, 
    {{ dbt_utils.split_part('var_name', "'_'", 1) }} as model_type,
    var_value as prefix_value
from vars_prefix_table