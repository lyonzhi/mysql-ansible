{% if master_ip in ansible_all_ipv4_addresses %}

{% else %}
stop slave;
{% endif %}
