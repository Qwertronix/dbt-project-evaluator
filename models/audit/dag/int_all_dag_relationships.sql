{% set debug_snowflake = var('debug_snowflake',false) %}

with recursive direct_relationships as (
    select  
        *
    from {{ ref('stg_direct_relationships') }}
),

-- recursive CTE
-- one record for every node and each of its downstream children (including itself)
all_relationships as (
    -- anchor 
    select distinct
        node as parent,
        node_id as parent_id,
        resource_type as parent_type,
        node as child,
        node_id as child_id,
        resource_type as child_type,
        0 as distance

        {% if debug_snowflake %}
        , array_construct(child) as path -- snowflake-specific, but helpful for troubleshooting  
        {% endif %}

    from direct_relationships
    -- where direct_parent is null {# optional lever to change filtering of anchor clause to only include root nodes #}
    
    union all

    -- recursive clause
    select  
        all_relationships.parent as parent,
        all_relationships.parent_id as parent_id,
        all_relationships.parent_type as parent_type,
        direct_relationships.node as child, 
        direct_relationships.node_id as child_id,
        direct_relationships.resource_type as child_type,
        all_relationships.distance+1 as distance

        {% if debug_snowflake %}
        , array_append(all_relationships.path, direct_relationships.node) as path
        {% endif %}

    from direct_relationships
    inner join all_relationships
        on all_relationships.child_id = direct_relationships.direct_parent_id
),

final as (
    select
        parent,
        parent_type,
        child,
        child_type,
        distance

        {% if debug_snowflake %}
        , path
        {% endif %}

    from all_relationships
)

select * from final
order by parent, distance