[styles.tables]
headers = {color = "{{ cursor }}"}
[styles.cpu]
all_entry_color = "{{ cursor }}"
avg_entry_color = "{{ color1 }}"
cpu_core_colors = ["{{ color1 }}","{{ color3 }}","{{ color3 }}","{{ color2 }}","{{ color6 }}","{{ color5 }}"]
[styles.memory]
ram_color = "{{ color2 }}"
swap_color = "{{ color3 }}"
gpu_colors = ["{{ color6 }}","{{ color5 }}","{{ color1 }}","{{ color3 }}","{{ color3 }}","{{ color2 }}"]
arc_color = "{{ color6 }}"
[styles.network]
rx_color = "{{ color2 }}"
tx_color = "{{ color1 }}"
[styles.widgets]
widget_title = {color = "{{ cursor }}"}
border_color = "{{ color8 }}"
selected_border_color = "{{ color5 }}"
text = {color = "{{ foreground }}"}
selected_text = {color = "{{ background }}", bg_color = "{{ color5 }}"}
[styles.graphs]
graph_color = "{{ color15 }}"
[styles.battery]
high_battery_color = "{{ color2 }}"
medium_battery_color = "{{ color3 }}"
low_battery_color = "{{ color1 }}"
