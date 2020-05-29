BEGIN {
    whoisdb_reload();
}

### BEGIN IP UTILITIES ###
function canonical_ip(_canonical_ip_ip) {
    split(_canonical_ip_ip,_canonical_ip_parts,".");
    _canonical_ip_result = sprintf("%03d.%03d.%03d.%03d",_canonical_ip_parts[1],_canonical_ip_parts[2],_canonical_ip_parts[3],_canonical_ip_parts[4]);
    return _canonical_ip_result;
}

function uncanonical_ip(_canonical_ip_ip) {
    split(_canonical_ip_ip,_canonical_ip_parts,".");
    _canonical_ip_result = sprintf("%d.%d.%d.%d",_canonical_ip_parts[1],_canonical_ip_parts[2],_canonical_ip_parts[3],_canonical_ip_parts[4]);
    return _canonical_ip_result;
}

function _decimal_to_boolean(num) {
    result = "";

    while (num > 1) {
        result = ((num % 2) result);
        num = int(num / 2);
    }

    result = (num result);

    return result;
}

function _boolean_to_decimal(val) {
    split(val,parts,"");
    result = 0;
    for (i=1; parts[i]!=""; i++) {
        result = (result * 2) + int(parts[i]);
    }
    return int(result);
}

function _ip_to_boolean(_ip_to_boolean_ip) {
    split(_ip_to_boolean_ip,_ip_to_boolean_parts,".");
    for (_ip_to_boolean_i=1;_ip_to_boolean_i<=4;_ip_to_boolean_i++) {
        if (_ip_to_boolean_parts[_ip_to_boolean_i]=="") {
            _ip_to_boolean_part = "0";
        } else {
            _ip_to_boolean_part = _decimal_to_boolean(int(_ip_to_boolean_parts[_ip_to_boolean_i]));
        }
        _ip_to_boolean_part = sprintf("%08s", _ip_to_boolean_part);
        for (_ip_to_boolean_j=1;_ip_to_boolean_j<=8;_ip_to_boolean_j++) {
            sub(/ /,"0",_ip_to_boolean_part);
        }
        _ip_to_boolean_result_parts[_ip_to_boolean_i] = _ip_to_boolean_part;
    }
    return sprintf("%s%s%s%s", _ip_to_boolean_result_parts[1], _ip_to_boolean_result_parts[2], _ip_to_boolean_result_parts[3], _ip_to_boolean_result_parts[4]);
}

function _boolean_to_ip(val) {
    _boolean_to_ip_parts[1] = _boolean_to_decimal(substr(val, 1, 8));
    _boolean_to_ip_parts[2] = _boolean_to_decimal(substr(val, 9, 8));
    _boolean_to_ip_parts[3] = _boolean_to_decimal(substr(val, 17, 8));
    _boolean_to_ip_parts[4] = _boolean_to_decimal(substr(val, 25, 8));
    return sprintf("%d.%d.%d.%d", _boolean_to_ip_parts[1], _boolean_to_ip_parts[2], _boolean_to_ip_parts[3], _boolean_to_ip_parts[4]);
}

function _boolean_and(left, right) {
    split(left,left_parts,"");
    split(right,right_parts,"");
    result = "";

    for (i=1; left_parts[i]!=""&&right_parts[i]!=""; i++) {
        if (int(left_parts[i])==int(right_parts[i])) {
            result = (result "" left_parts[i]);
        } else {
            result = (result "0");
        }
    }

    return result;
}

function _boolean_or(left, right) {
    split(left,left_parts,"");
    split(right,right_parts,"");
    result = "";

    for (i=1; left_parts[i]!=""&&right_parts[i]!=""; i++) {
        if (int(left_parts[i])==1 || int(right_parts[i])==1) {
            result = (result "1");
        } else {
            result = (result "0");
        }
    }

    return result;
}

function _boolean_xor(left, right) {
    split(left,left_parts,"");
    split(right,right_parts,"");
    _boolean_xor_result = "";

    for (_boolean_xor_counter=1; left_parts[_boolean_xor_counter]!=""&&right_parts[_boolean_xor_counter]!=""; _boolean_xor_counter++) {
        if ((int(left_parts[_boolean_xor_counter]) + int(right_parts[_boolean_xor_counter])) == 1) {
            _boolean_xor_result = (_boolean_xor_result "1");
        } else {
            _boolean_xor_result = (_boolean_xor_result "0");
        }
    }

    return _boolean_xor_result;
}

function _cidr_low_bitmask(count) {
    result = "";
    for (i=1; i<=count; i++) {
        result = (result "1");
    }
    for (i=count; i<=32; i++) {
        result = (result "0");
    }
    return result;
}

function _cidr_high_bitmask(count) {
    result = "";
    for (i=1; i<=count; i++) {
        result = (result "0");
    }
    for (i=count; i<=32; i++) {
        result = (result "1");
    }
    return result;
}

function cidr_netmask(_cidr_netmask_cidr) {
    _cidr_netmask_idx = match(_cidr_netmask_cidr,/\//);
    if (_cidr_netmask_idx == 0) {
        return "";
    }

    _cidr_netmask_ip = substr(_cidr_netmask_cidr, 0, _cidr_netmask_idx - 1);
    _cidr_netmask_count = substr(_cidr_netmask_cidr, _cidr_netmask_idx + 1);

    sub(/^\s*/,"",_cidr_netmask_ip);
    sub(/^\s*/,"",_cidr_netmask_count);
    sub(/\s*$/,"",_cidr_netmask_ip);
    sub(/\s*$/,"",_cidr_netmask_count);

    _cidr_netmask_count = int(_cidr_netmask_count);

    return canonical_ip(_boolean_to_ip(_cidr_low_bitmask(_cidr_netmask_count)));
}

function cidr_start_ip(_cidr_start_ip_cidr) {
    _cidr_start_ip_idx = match(_cidr_start_ip_cidr,/\//);
    if (_cidr_start_ip_idx == 0) {
        return "";
    }

    _cidr_start_ip_ip = substr(_cidr_start_ip_cidr, 0, _cidr_start_ip_idx - 1);
    _cidr_start_ip_count = substr(_cidr_start_ip_cidr, _cidr_start_ip_idx + 1);

    sub(/^\s*/,"",_cidr_start_ip_ip);
    sub(/^\s*/,"",_cidr_start_ip_count);
    sub(/\s*$/,"",_cidr_start_ip_ip);
    sub(/\s*$/,"",_cidr_start_ip_count);

    _cidr_start_ip_count = int(_cidr_start_ip_count);

    return canonical_ip(_boolean_to_ip(_boolean_and(_ip_to_boolean(_cidr_start_ip_ip), _cidr_low_bitmask(_cidr_start_ip_count))));
}

function cidr_end_ip(_cidr_end_ip_cidr) {
    _cidr_end_ip_idx = match(_cidr_end_ip_cidr,/\//);
    if (_cidr_end_ip_idx == 0) {
        return "";
    }

    _cidr_end_ip_ip = substr(_cidr_end_ip_cidr, 0, _cidr_end_ip_idx - 1);
    _cidr_end_ip_count = substr(_cidr_end_ip_cidr, _cidr_end_ip_idx + 1);

    sub(/^\s*/,"",_cidr_end_ip_ip);
    sub(/^\s*/,"",_cidr_end_ip_count);
    sub(/\s*$/,"",_cidr_end_ip_ip);
    sub(/\s*$/,"",_cidr_end_ip_count);

    _cidr_end_ip_count = int(_cidr_end_ip_count);

    return canonical_ip(_boolean_to_ip(_boolean_or(_ip_to_boolean(_cidr_end_ip_ip), _cidr_high_bitmask(_cidr_end_ip_count))));
}

function ip_range_to_cidr(_iprange_to_cidr_start_ip, _iprange_to_cidr_end_ip) {
    _iprange_to_cidr_start_ip = canonical_ip(_iprange_to_cidr_start_ip);
    _iprange_to_cidr_end_ip = canonical_ip(_iprange_to_cidr_end_ip);
    _iprange_to_cidr_xor_result = _boolean_xor(_ip_to_boolean(_iprange_to_cidr_start_ip), _ip_to_boolean(_iprange_to_cidr_end_ip))

    split(_iprange_to_cidr_xor_result,_iprange_to_cidr_xor_parts,"");
    _iprange_to_cidr_cidr_range = 32;
    _iprange_to_cidr_cidr_range_found = 0;

    for (_iprange_to_cidr_counter=32; _iprange_to_cidr_counter>=1; _iprange_to_cidr_counter--) {
        if (_iprange_to_cidr_cidr_range_found == 0) {
            if (_iprange_to_cidr_xor_parts[_iprange_to_cidr_counter] == "1") {
                _iprange_to_cidr_cidr_range = _iprange_to_cidr_cidr_range - 1;
            } else if (_iprange_to_cidr_xor_parts[_iprange_to_cidr_counter] == "0") {
                _iprange_to_cidr_cidr_range_found = 1;
            } else {
                print "ERROR: UNEXPECTED OPERATION WHILE CALCULATING CIDR i=" _iprange_to_cidr_counter " part=" _iprange_to_cidr_xor_parts[_iprange_to_cidr_counter] " xor_result=" _iprange_to_cidr_xor_result;
            }
        } else {
            if (_iprange_to_cidr_xor_parts[_iprange_to_cidr_counter] == "1") {
                print "WARN: no CIDR could be constructed from [" _iprange_to_cidr_start_ip "] - [" _iprange_to_cidr_end_ip "] xor_result=" _iprange_to_cidr_xor_result;
                return "";
            } else if (_iprange_to_cidr_xor_parts[_iprange_to_cidr_counter] != "0") {
                print "ERROR: UNEXPECTED OPERATION WHILE CALCULATING CIDR";
            }
        }
    }

    return uncanonical_ip(_iprange_to_cidr_start_ip) "/" _iprange_to_cidr_cidr_range;
}
### END IP UTILITIES ###

### BEGIN DATABASE ###
function whoisdb_init() {
    WHOISDB["length"] = 0;
    WHOISDB["dirty"] = 0;
    WHOISDB["start_ips"]["length"] = 0;
    WHOISDB["is_rebuild"] = 0;
}

function _whoisdb_append_field_only(idx, field) {
    _whoisdb_append_field_n = WHOISDB["records"][idx]["fields_length"];

    for (_whoisdb_append_i = 1; _whoisdb_append_i <= _whoisdb_append_field_n; _whoisdb_append_i++) {
        if (WHOISDB["records"][idx]["fields"][_whoisdb_append_i] == field) {
            return "";
        }
    }

    _whoisdb_append_field_n = _whoisdb_append_field_n + 1;
    WHOISDB["records"][idx]["fields_length"] = _whoisdb_append_field_n;
    WHOISDB["records"][idx]["fields"][_whoisdb_append_field_n] = field;
    WHOISDB["records"][idx]["values"][field]["length"] = 0;
    WHOISDB["dirty"] = 1;
}

function whoisdb_set_field(idx, field, value) {
    _whoisdb_append_field_only(idx, field);
    WHOISDB["records"][idx]["values"][field]["length"] = 1;
    WHOISDB["records"][idx]["values"][field]["items"][1] = value;
    WHOISDB["dirty"] = 1;
}

function whoisdb_append_field(idx, field, value) {
    _whoisdb_append_field_only(idx, field);
    _whoisdb_append_field_n = WHOISDB["records"][idx]["values"][field]["length"] + 1;
    WHOISDB["records"][idx]["values"][field]["length"] = _whoisdb_append_field_n;
    WHOISDB["records"][idx]["values"][field]["items"][_whoisdb_append_field_n] = value;
    WHOISDB["dirty"] = 1;
}

function whoisdb_new_record() {
    _whoisdb_new_record = WHOISDB["length"] + 1;
    WHOISDB["length"] = _whoisdb_new_record;
    WHOISDB["records"][_whoisdb_new_record]["fields_length"] = 0;
    WHOISDB["dirty"] = 1;

    return _whoisdb_new_record;
}

function whoisdb_pop_record() {
    _whoisdb_new_record = WHOISDB["length"] - 1;
    WHOISDB["length"] = _whoisdb_new_record;
    WHOISDB["dirty"] = 1;
}

function whoisdb_length() {
    return WHOISDB["length"];
}

function whoisdb_get_field_length(idx, field) {
    _whoisdb_get_value_count = WHOISDB["records"][idx]["values"][field]["length"];
    if (_whoisdb_get_value_count == "") {
        return 0;
    }
    return _whoisdb_get_value_count;
}

function whoisdb_get_field(idx, field, field_idx) {
    return WHOISDB["records"][idx]["values"][field]["items"][field_idx];
}

function whoisdb_get_origin(idx) {
    return whoisdb_get_field(idx, "__ORIGIN__", 1);
}

function _whoisdb_get_iprange(idx, iprange_index) {
    offset = 0;
    range = whoisdb_get_field(idx, "NetRange", iprange_index - offset);
    if (range != "") {
        return range;
    }
    offset = offset + whoisdb_get_field_length(idx, "NetRange");

    range = whoisdb_get_field(idx, "inetnum", iprange_index - offset);
    if (range != "") {
        return range;
    }
    offset = offset + whoisdb_get_field_length(idx, "inetnum");

    range = whoisdb_get_field(idx, "IPv4 Address", iprange_index - offset);
    if (range != "") {
        return range;
    }
    offset = offset + whoisdb_get_field_length(idx, "IPv4 Address");

    range = whoisdb_get_field(idx, "Network Number", iprange_index - offset);
    if (range != "") {
        return range;
    }
    offset = offset + whoisdb_get_field_length(idx, "Network Number");

    range = whoisdb_get_field(idx, "CIDR", iprange_index - offset);
    if (range != "") {
        return range;
    }
    offset = offset + whoisdb_get_field_length(idx, "CIDR");

    return "";
}

function _whoisdb_get_iprange_length(idx) {
    _iprange_length = whoisdb_get_field_length(idx, "NetRange");
    _iprange_length = _iprange_length + whoisdb_get_field_length(idx, "inetnum");
    _iprange_length = _iprange_length + whoisdb_get_field_length(idx, "IPv4 Address");
    _iprange_length = _iprange_length + whoisdb_get_field_length(idx, "Network Number");
    _iprange_length = _iprange_length + whoisdb_get_field_length(idx, "CIDR");

    return _iprange_length;
}

function whoisdb_get_ip_start(idx, iprange_index) {
    result_record_ip_start = whoisdb_get_field(idx, "__START_IP__", iprange_index);
    if (result_record_ip_start != "") {
        return result_record_ip_start;
    }

    result_record_ip_start = _whoisdb_get_ip_start(idx, iprange_index);
    if (result_record_ip_start != "") {
        whoisdb_append_field(idx, "__START_IP__", result_record_ip_start);
    }
    return result_record_ip_start;
}

function _whoisdb_get_ip_start(idx, iprange_index) {
    _get_whois_record_ip_start_range = _whoisdb_get_iprange(idx, iprange_index);
    if (iprange_index > 1 && _get_whois_record_ip_start_range == "") {
        return "";
    }

    if (_get_whois_record_ip_start_range ~ /[0-9][0-9]*(\.[0-9][0-9]*(\.[0-9][0-9]*(\.[0-9][0-9]*)?)?)?\s*\/\s*[0-9][0-9]*/) {
        ip_start = cidr_start_ip(_get_whois_record_ip_start_range);
        ip_end = cidr_end_ip(_get_whois_record_ip_start_range);

        if (ip_start != "" && ip_end != "" && ip_start != "000.000.000.000" && ip_end != "000.000.000.000") {
            return ip_start;
        }

        print "ERROR: (1) PARSING ip_start [" _get_whois_record_ip_start_range "] FOR INDEX [" idx "] FROM [" _get_whois_record_ip_start_range "] ORIGIN=[" whoisdb_get_origin(idx) "]";
        return "";
    }

    if (_get_whois_record_ip_start_range !~ /[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\s*-\s*[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*/) {
        print "ERROR: (2) FAILED TO PARSE IP ip_start FOR IDX=" idx " (iprange_index=" iprange_index ") FROM [" _get_whois_record_ip_start_range "] ORIGIN=[" whoisdb_get_origin(idx) "]";
        return "";
    }

    split(_get_whois_record_ip_start_range, _get_whois_ip_ranges_start_ip_ranges, "-");
    sub(/^\s*/, "", _get_whois_ip_ranges_start_ip_ranges[1]);
    sub(/^\s*/, "", _get_whois_ip_ranges_start_ip_ranges[2]);
    sub(/\s*$/, "", _get_whois_ip_ranges_start_ip_ranges[1]);
    sub(/\s*$/, "", _get_whois_ip_ranges_start_ip_ranges[2]);

    if (_get_whois_ip_ranges_start_ip_ranges[1] != "" && _get_whois_ip_ranges_start_ip_ranges[2] != "") {
        _get_whois_record_ip_start_ip_ranges_start = canonical_ip(_get_whois_ip_ranges_start_ip_ranges[1]);
        _get_whois_record_ip_start_ip_ranges_end = canonical_ip(_get_whois_ip_ranges_start_ip_ranges[2]);

        if (_get_whois_record_ip_start_ip_ranges_start != "" && _get_whois_record_ip_start_ip_ranges_end != "" && _get_whois_record_ip_start_ip_ranges_start != "000.000.000.000" && _get_whois_record_ip_start_ip_ranges_end != "000.000.000.000") {
            return _get_whois_record_ip_start_ip_ranges_start;
        }
    }

    print "ERROR: (3) FAILED TO PARSE ip_start IP RANGE FOR IDX=" idx " FROM " _get_whois_record_ip_start_range " ORIGIN=[" whoisdb_get_origin(idx) "]";
    return "";
}

function whoisdb_get_ip_end(idx, iprange_index) {
    result_record_ip_end = whoisdb_get_field(idx, "__IP_END__", iprange_index);
    if (result_record_ip_end != "") {
        return result_record_ip_end;
    }

    result_record_ip_end = _whoisdb_get_ip_end(idx, iprange_index);
    if (result_record_ip_end != "") {
        whoisdb_append_field(idx, "__IP_END__", result_record_ip_end);
    }

    return result_record_ip_end;
}

function _whoisdb_get_ip_end(idx, iprange_index) {
    range = _whoisdb_get_iprange(idx, iprange_index);
    if (iprange_index > 1 && range == "") {
        return "";
    }

    if (range ~ /[0-9][0-9]*(\.[0-9][0-9]*(\.[0-9][0-9]*(\.[0-9][0-9]*)?)?)?\s*\/\s*[0-9][0-9]*/) {
        ip_start = cidr_start_ip(range);
        ip_end = cidr_end_ip(range);

        if (ip_start != "" && ip_end != "" && ip_start != "000.000.000.000" && ip_end != "000.000.000.000") {
            return ip_end;
        }

        print "ERROR: (4) PARSING [" range "] FOR INDEX [" idx "] FROM [" range "] ORIGIN=[" whoisdb_get_origin(idx) "]";
        return "";
    }

    if (range !~ /[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\s*-\s*[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*/) {
        print "ERROR: (5) FAILED TO PARSE IP RANGE FOR IDX=" idx " (iprange_index=" iprange_index ") FROM [" range "] ORIGIN=[" whoisdb_get_origin(idx) "]";
        return "";
    }

    split(range, ip_ranges, "-");
    sub(/^\s*/, "", ip_ranges[1]);
    sub(/^\s*/, "", ip_ranges[2]);
    sub(/\s*$/, "", ip_ranges[1]);
    sub(/\s*$/, "", ip_ranges[2]);

    if (ip_ranges[1] != "" && ip_ranges[2] != "") {
        ip_start = canonical_ip(ip_ranges[1]);
        ip_end = canonical_ip(ip_ranges[2]);

        if (ip_start != "" && ip_end != "" && ip_start != "000.000.000.000" && ip_end != "000.000.000.000") {
            return ip_end;
        }
    }

    print "ERROR: (6) FAILED TO PARSE IP RANGE FOR IDX=" idx " FROM [" range "] ORIGIN=[" whoisdb_get_origin(idx) "]";
    return "";
}

function whoisdb_reload() {
    whoisdb_init();

    while ((getline line < "whois.db") > 0) {
        idx = whoisdb_new_record();
        split(line, parts, "`")

        n = int(parts[1]);
        for (i=2; i<=n;) {
            field = parts[i];
            value_length = int(parts[i+1]);

            i = i + 2;

            for (j=1; j<=value_length; j++) {
                value = parts[i + j - 1];
                whoisdb_append_field(idx, field, value)
            }

            i = i + value_length;
        }
    }

    close("whois.db");
    
    for (rebuild_counter=1; rebuild_counter<=whoisdb_length(); rebuild_counter++) {
        for (rebuild_iprange_counter=1; ;rebuild_iprange_counter++) {
            start = whoisdb_get_ip_start(rebuild_counter, rebuild_iprange_counter);
            if (start == "") {
                break;
            }

            whois_records_start_ips_length = WHOISDB["start_ips"]["length"] + 1;
            WHOISDB["start_ips"]["length"] = whois_records_start_ips_length;
            WHOISDB["start_ips"]["items"][whois_records_start_ips_length] = start;
            WHOISDB["start_ips"]["indices"][whois_records_start_ips_length] = rebuild_counter;

            for (rebuild_sort_counter = whois_records_start_ips_length; rebuild_sort_counter >= 2; rebuild_sort_counter--) {
                next_rebuild_sort_counter = rebuild_sort_counter - 1;
                next_rebuild_sort_start = WHOISDB["start_ips"]["items"][next_rebuild_sort_counter];
                next_rebuild_sort_index = WHOISDB["start_ips"]["indices"][next_rebuild_sort_counter];

                if (start < next_rebuild_sort_start) {
                    WHOISDB["start_ips"]["items"][next_rebuild_sort_counter] = start;
                    WHOISDB["start_ips"]["items"][rebuild_sort_counter] = next_rebuild_sort_start;

                    WHOISDB["start_ips"]["indices"][next_rebuild_sort_counter] = rebuild_counter;
                    WHOISDB["start_ips"]["indices"][rebuild_sort_counter] = next_rebuild_sort_index;
                }
            }
        }
    }

    WHOISDB["dirty"] = 0;
}

function _whoisdb_parse_field(line) {
    idx = match(line, /^\s*%/);
    if (idx != 0) {
        return "";
    }

    idx = match(line, /^\s*#/);
    if (idx != 0) {
        return "";
    }

    if (line ~ /^\s*[a-zA-Z0-9][a-zA-Z0-9]*\s*\.\s*\[[a-zA-Z0-9. \/\\()\-][a-zA-Z0-9. \/\\()\-]*\]\s*[a-zA-Z0-9. \/\\()\-][a-zA-Z0-9. \/\\()\-]*$/) {
        idx = match(line, /\[[a-zA-Z0-9. \/\\()\-][a-zA-Z0-9. \/\\()\-]*\]/);
        if (idx == 0) {
            return "";
        }
        line = substr(line, idx + 1);

        idx = match(line, /\]/);
        if (idx == 0) {
            return "";
        }
        line = substr(line, 1, idx - 1);

        sub(/^\s*/, "", line);
        sub(/\s*$/, "", line);

        return line;
    }

    idx = match(line, /[a-zA-Z]/);
    if (idx == 0) {
        return "";
    }
    line = substr(line, idx);

    idx = match(line, /:/)
    if (idx == 0) {
        return "";
    }
    line = substr(line, 1, idx - 1);

    sub(/\s*$/, "", line);

    return line;
}

function _whoisdb_parse_value(line) {
    idx = match(line, /^\s*%/);
    if (idx != 0) {
        return "";
    }

    idx = match(line, /^\s*#/);
    if (idx != 0) {
        return "";
    }

    if (line ~ /^\s*[a-zA-Z0-9][a-zA-Z0-9]*\s*\.\s*\[[a-zA-Z0-9. \/\\()\-][a-zA-Z0-9. \/\\()\-]*\]\s*[a-zA-Z0-9. \/\\()\-][a-zA-Z0-9. \/\\()\-]*$/) {
        idx = match(line, /\]/);
        if (idx == 0) {
            return "";
        }
        line = substr(line, idx + 1);

        sub(/^\s*/, "", line);
        sub(/\s*$/, "", line);

        return line;
    }

    idx = match(line, /:/);
    if (idx == 0) {
        return "";
    }
    line = substr(line, idx + 1);

    sub(/^\s*/, "", line);
    sub(/\s*$/, "", line);

    return line;
}

function _whoisdb_discard_seperator(a_line) {
    continue_discard_seperator = 1;

    while (continue_discard_seperator == 1) {
        prev_a_line = a_line;
        sub(/`/,"",a_line);
        if (prev_a_line == a_line) {
            continue_discard_seperator = 0;
        }
    }

    return a_line;
}

function _whoisdb_fetch_whois(ip) {
    print "INFO: [fetching.. " ip "]";
    lines_length = 0;
    cache_file = "cache/" ip;
    read_cache_file_cmd = ("cat " cache_file);

    while (read_cache_file_cmd | getline line) {
        line = _whoisdb_discard_seperator(line);

        lines_length = lines_length + 1;
        lines[lines_length] = line;

        if (lines[i] ~ /temporary unable to query/) {
            print "ERROR: (cache) [TEMPORARY UNABLE TO QUERY '" ip "']"
            lines_length = 0;
            break;
        }
    }
    close(line);
    close(cache_file);
    close(read_cache_file_cmd);

    if (lines_length == 0) {
        if (WHOISDB["is_rebuild"] == 1) {
            print "ERROR: no fetch should happend during rebuild, while processing ip=[" ip "]";
            return "";
        }

        cmd = ("whois " ip);

        print "INFO: [contacting whois..]";
        while (cmd | getline line) {
            line = _whoisdb_discard_seperator(line);

            lines_length = lines_length + 1;
            lines[lines_length] = line;

            if (line ~ /temporary unable to query/) {
                print "ERROR: [TEMPORARY UNABLE TO QUERY '" ip "']"
                return "";
            }
        }
        close(line);
        close(cmd);

        for (i=1; i<=lines_length; i++) {
            print(lines[i]) >> cache_file;
        }
        close(cache_file);
    }

    fields_length = 0;
    _whoisdb_fetch_whois_new_record = whoisdb_new_record();

    for (i=1; i<=lines_length; i++) {
        field = _whoisdb_parse_field(lines[i]);
        value = _whoisdb_parse_value(lines[i]);

        if (field != "" && value != "") {
            whoisdb_append_field(_whoisdb_fetch_whois_new_record, field, value);
            fields_length = fields_length + 1;
        }
    }

    if (fields_length == 0) {
        for (i=1; i<=lines_length; i++) {
            if (lines[i] !~ /\s*%/ && lines[i] !~ /\s*#/ && lines[i] ~ /[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\s*-\s*[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*/) {
                idx = match(lines[i], /[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\s*-\s*[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*/);
                if (idx != 0) {
                    owner = substr(lines[i], 1, idx - 1);
                    range = substr(lines[i], idx);

                    sub(/^\s*/,"",owner);
                    sub(/^\s*/,"",range);
                    sub(/\s*$/,"",owner);
                    sub(/\s*$/,"",range);

                    whoisdb_append_field(_whoisdb_fetch_whois_new_record, "NetRange", range);
                    whoisdb_append_field(_whoisdb_fetch_whois_new_record, "OrgName", owner);

                    fields_length = 2;
                }
            }
        }
    }

    if (fields_length == 0) {
        print "ERROR: UNABLE TO EXTRACT WHOIS FIELDS";
        whoisdb_pop_record();

        for (i=1; i<=lines_length; i++) {
            print "ERROR: DBG: [" i "]: " lines[i];
        }

        return "";
    }

    whoisdb_set_field(_whoisdb_fetch_whois_new_record, "__ORIGIN__", ip);

    print "INFO: [ fetch done ]";
}

function whoisdb_save() {
    if (WHOISDB["dirty"] == 0) {
        return "";
    }

    n = whoisdb_length();
    for (i=1; i<=n; i++) {
        fields_length = WHOISDB["records"][i]["fields_length"];
        printed_parts_count = 1;
        for (j=1; j<= fields_length; j++) {
            field = WHOISDB["records"][i]["fields"][j];
            field_length = WHOISDB["records"][i]["values"][field]["length"];
            printed_parts_count = printed_parts_count + 2 + field_length;
        }

        out_line = "" printed_parts_count;
        for (j=1; j<= fields_length; j++) {
            field = WHOISDB["records"][i]["fields"][j];
            field_length = WHOISDB["records"][i]["values"][field]["length"];
            out_line = (out_line "`" field "`" field_length);
            
            for (k=1; k<= field_length; k++) {
                value = WHOISDB["records"][i]["values"][field]["items"][k];
                out_line = (out_line "`" value);
            }
        }

        if (i == 1) {
            print(out_line) > "whois.db";
        } else {
            print(out_line) >> "whois.db";
        }
    }

    close("whois.db");

    whoisdb_reload();
}

function _whoisdb_lookup(ip) {
    target_ip = canonical_ip(ip);

    for (_get_whois_record_index_by_ip_counter=1; _get_whois_record_index_by_ip_counter<=whoisdb_length(); _get_whois_record_index_by_ip_counter++) {
        for (_whois_lookup_iprange_counter=1; ;_whois_lookup_iprange_counter++) {
            start_ip = whoisdb_get_ip_start(_get_whois_record_index_by_ip_counter, _whois_lookup_iprange_counter);
            end_ip = whoisdb_get_ip_end(_get_whois_record_index_by_ip_counter, _whois_lookup_iprange_counter);

            if (start_ip == "" || end_ip == "") {
                break;
            }

            if (target_ip >= start_ip && target_ip <= end_ip) {
                return _get_whois_record_index_by_ip_counter;
            }
        }
    }

    return 0;
}

function whoisdb_lookup(ip) {
    target_ip = canonical_ip(ip);

    bs_start = 1;
    bs_end = WHOISDB["start_ips"]["length"] + 1;
    #print "> start=" bs_start " end=" bs_end " target=" target_ip;

    while ((bs_end - bs_start) > 1) {
        mid = int((bs_start + bs_end) / 2);
        mid_value = WHOISDB["start_ips"]["items"][mid];

        if (target_ip < mid_value) {
            #print "> start=" bs_start " end=" bs_end " mid=" mid " mid_value=" mid_value " (target_ip < mid_value)";
            bs_end = mid;
        } else {
            #print "> start=" bs_start " end=" bs_end " mid=" mid " mid_value=" mid_value " (target_ip >= mid_value)";
            bs_start = mid;
        }
    }

    if (bs_start < bs_end) {
        bs_start = WHOISDB["start_ips"]["indices"][bs_start];
        #print "?> index=" bs_start;

        for (bs_iprange_counter=1; ;bs_iprange_counter++) {
            start_ip = whoisdb_get_ip_start(bs_start, bs_iprange_counter);
            end_ip = whoisdb_get_ip_end(bs_start, bs_iprange_counter);

            if (start_ip == "" || end_ip == "") {
                break;
            }

            #print ">> start_ip=" start_ip " end_ip=" end_ip;

            if (target_ip >= start_ip && target_ip <= end_ip) {
                if (WHOISDB["is_rebuild"] == 1) {
                    print "ERROR: LOOKUP SHOULD HAD FAILED WHILE IN REBUILD (ip=" ip ") BUT MATCHED VIA (ORIGIN=" whoisdb_get_origin(bs_start) ")";
                }
                return bs_start;
            }
        }
    }

    #print "ERROR: binary search failed";

    result = _whoisdb_lookup(ip);
    if (result == 0) {
        _whoisdb_fetch_whois(ip);

        result = _whoisdb_lookup(ip);
        if (result == 0) {
            return 0;
        }
    } else {
        if (WHOISDB["is_rebuild"] == 1) {
            print "ERROR: LOOKUP SHOULD HAD FAILED WHILE IN REBUILD (ip=" ip ") BUT MATCHED VIA (ORIGIN=" whoisdb_get_origin(result) ")";
        }
    }

    return result;
}

function whoisdb_get_phone(idx, phone_index) {
    result_phone = whoisdb_get_field(idx, "__PHONE__", phone_index);
    if (result_phone != "") {
        return result_phone;
    }

    result_phone = _whoisdb_get_phone(idx, phone_index);
    if (result_phone != "") {
        whoisdb_append_field(idx, "__PHONE__", result_phone);
    }

    return result_phone;
}

function _whoisdb_get_phone(idx, phone_index) {
    result = whoisdb_get_field(idx, "Phone", phone_index);
    if (result != "") {
        return result;
    }

    return "";
}

function whoisdb_get_phone_length(idx) {
    return whoisdb_get_field_length(idx, "Phone");
}

function whoisdb_get_owner(idx, owner_index) {
    result_owner = whoisdb_get_field(idx, "__OWNER__", owner_index);
    if (result_owner != "") {
        return result_owner;
    }

    result_owner = _whoisdb_get_owner(idx, owner_index);
    if (result_owner != "") {
        whoisdb_append_field(idx, "__OWNER__", result_owner);
    }

    return result_owner;
}

function _whoisdb_get_owner(idx, owner_index) {
    owner_offset = 0;

    result = whoisdb_get_field(idx, "OrgName", owner_index - owner_offset);
    if (result != "") {
        return result;
    }
    owner_offset = owner_offset + whoisdb_get_field_length(idx, "OrgName");

    result = whoisdb_get_field(idx, "owner", owner_index - owner_offset);
    if (result != "") {
        return result;
    }
    owner_offset = owner_offset + whoisdb_get_field_length(idx, "owner");

    result = whoisdb_get_field(idx, "Organization", owner_index - owner_offset);
    if (result != "") {
        return result;
    }
    owner_offset = owner_offset + whoisdb_get_field_length(idx, "Organization");

    result = whoisdb_get_field(idx, "netname", owner_index - owner_offset);
    if (result != "") {
        return result;
    }
    owner_offset = owner_offset + whoisdb_get_field_length(idx, "netname");

    return "";
}

function whoisdb_get_owner_length(idx) {
    return whoisdb_get_field_length(idx, "OrgName") + whoisdb_get_field_length(idx, "owner") + whoisdb_get_field_length(idx, "Organization") + whoisdb_get_field_length(idx, "netname");
}

function whoisdb_get_country(idx) {
    result_country = whoisdb_get_field(idx, "__COUNTRY__", 1);
    if (result_country != "") {
        return result_country;
    }

    result_country = _whoisdb_get_country(idx);
    if (result_country != "") {
        whoisdb_set_field(idx, "__COUNTRY__", result_country);
    }

    return result_country;
}

function _whoisdb_get_country(idx) {
    _whoisdb_country_result = "";

    for (_whoisdb_country_counter=1; ;_whoisdb_country_counter++) {
        _whoisdb_country_part = __whoisdb_get_country(idx, _whoisdb_country_counter);
        if (_whoisdb_country_part == "") {
            return _whoisdb_country_result;
        }
        if (_whoisdb_country_part == "IR") {
            return "IR";
        }
        if (_whoisdb_country_part != "--") {
            _whoisdb_country_result = _whoisdb_country_part;
        }
    }
}

function __whoisdb_get_country(idx, country_index) {
    offset = 0;
    result = whoisdb_get_field(idx, "Country", country_index - offset);
    if (result != "") {
        result = toupper(result);
        if (result ~ /^EU/) {
            return "EU";
        }
        return result;
    }
    offset = offset + whoisdb_get_field_length(idx, "Country")

    result = whoisdb_get_field(idx, "country", country_index - offset);
    if (result != "") {
        result = toupper(result);
        if (result ~ /^EU/) {
            return "EU";
        }
        return result;
    }
    offset = offset + whoisdb_get_field_length("country")

    phone = whoisdb_get_phone(idx, country_index - offset);
    if (phone != "") {
        if (phone ~ /[+]82/) {
            return "KR";
        }
        if (phone ~ /[+]98/) {
            return "IR";
        }
        return "--";
    }
    offset = offset + whoisdb_get_phone_length(idx);

    owner = whoisdb_get_owner(idx, country_index - offset);
    if (owner != "") {
        if (owner ~ /24Shells/) {
            return "US";
        }
        if (owner ~ /Maxihost/) {
            return "BR";
        }
        if (owner ~ /SoftEther/) {
            return "JP";
        }
        return "--";
    }
    offset = offset + whoisdb_get_owner_length(idx);

    nameserver = whoisdb_get_field(idx, "Nameserver", country_index - offset);
    if (nameserver != "") {
        if (nameserver ~ /\.jp$/) {
            return "JP";
        }
        if (nameserver ~ /\.ir$/) {
            return "IR";
        }
        return "--";
    }
    offset = offset + whoisdb_get_field_length(idx, "Nameserver");

    netname = whoisdb_get_field(idx, "netname", country_index - offset);
    if (netname != "") {
        if (toupper(netname) ~ /^IR-/) {
            return "IR";
        }
        return "--";
    }
    offset = offset + whoisdb_get_field_length(idx, "netname");

    mnt = whoisdb_get_field(idx, "mnt-by", country_index - offset);
    if (mnt != "") {
        if (toupper(mnt) ~ /^IR-/) {
            return "IR";
        }
        return "--";
    }
    offset = offset + whoisdb_get_field_length(idx, "mnt-by");

    descr = whoisdb_get_field(idx, "descr", country_index - offset);
    if (descr != "") {
        if (toupper(descr) ~ /IRAN/) {
            return "IR";
        }
        return "--";
    }
    offset = offset + whoisdb_get_field_length(idx, "descr");

    address = whoisdb_get_field(idx, "address", country_index - offset);
    if (address != "") {
        if (toupper(address) ~ /IRAN/) {
            return "IR";
        }
        if (toupper(address) ~ /TEHRAN/) {
            return "IR";
        }
        return "--";
    }
    offset = offset + whoisdb_get_field_length(idx, "address");

    return "";
}

function whoisdb_get_iran_isp(idx) {
    result_isp = whoisdb_get_field(idx, "__IRAN_ISP__", 1);
    if (result_isp != "") {
        return result_isp;
    }

    result_isp = _whoisdb_get_iran_isp(idx);
    if (result_isp != "") {
        whoisdb_set_field(idx, "__IRAN_ISP__", result_isp);
    }

    return result_isp;
}

function _whoisdb_get_iran_isp(idx) {
    for (isp_counter=1; ;isp_counter++) {
        isp_result = __whoisdb_get_iran_isp(idx, isp_counter);
        if (isp_result == "") {
            return "";
        } else if (isp_result != "-") {
            return isp_result;
        }
    }
}

function __whoisdb_get_iran_isp(idx, isp_counter) {
    offset = 0;
    mnt = whoisdb_get_field(idx, "mnt-by", isp_counter - offset);
    if (mnt != "") {
        return __whoisdb_get_iran_isp_from_mnt(mnt);
    }
    offset = offset + whoisdb_get_field_length(idx, "mnt-by");

    owner = whoisdb_get_owner(idx, isp_counter - offset);
    if (owner != "") {
        return __whoisdb_get_iran_isp_from_owner(owner);
    }
    offset = offset + whoisdb_get_owner_length(idx);

    descr = whoisdb_get_field(idx, "descr", isp_counter - offset);
    if (descr != "") {
        return __whoisdb_get_iran_isp_from_description(descr);
    }
    offset = offset + whoisdb_get_field_length(idx, "descr");

    return "";
}

function __whoisdb_get_iran_isp_from_description(descr) {
    descr = toupper(descr);

    if (descr ~ /TELECOMMUNICATION COMPANY/) {
        return "Iran Telecommunication Company";
    }
    if (descr ~ /ORUM TORKAN RAYANEH/) {
        return "Torka Net"
    }

    return "";
}

function __whoisdb_get_iran_isp_from_mnt(mnt) {
    mnt = toupper(mnt);

    if (mnt == "TCI-RIPE-MNT" || mnt == "MNT-TCF" || mnt == "MK1-MNT" || mnt == "MNT-TCSEM" || mnt == "TIC-OBJECT-MNT") {
        return "Iran Telecommunication Company";
    }
    if (mnt ~ /^MCCI[0-9]*-MNT[0-9]*?$/) {
        return "Hamrah Avval";
    }
    if (mnt == "MNT-MOBINNET") {
        return "Mobin Net";
    }
    if (mnt == "MNT-ASIATECH" || mnt == "ASIATECH-MNT") {
        return "Asia Tech";
    }
    if (mnt == "MNT-MABNA") {
        return "Mabna Telecom";
    }
    if (mnt == "PARSONLINE-MNT") {
        return "Pars Online";
    }
    if (mnt == "IRANCELL-MNT") {
        return "Iran Cell";
    }
    if (mnt == "MNT-BOOM") {
        return "Boomerang Rayaneh";
    }
    if (mnt == "MNT-DATAK") {
        return "Datak";
    }
    if (mnt == "PTE-MNT" || mnt == "PISHGAMAN-MNT") {
        return "Pishgaman";
    }
    if (mnt ~ /^MNT-ASK[0-9]*$/) {
        return "Andisheh Sabz Khazar";
    }
    if (mnt ~ /^IR-RAYANKADEH-APADANA-[0-9]*-MNT$/) {
        return "Satia"
    }
    if (mnt ~ /^IR-ATRIN-[0-9]*-MNT$/) {
        return "Atrin Net";
    }
    if (mnt == "AFRA-MNT-NESH-1") {
        return "Afra Net";
    }
    if (mnt == "IR-FARABORD-MNT") {
        return "Zitel";
    }
    if (mnt == "MNT-MIHAN" || mnt == "MNT-HAMED") {
        return "Samaneh haye Ertebati Mihan";
    }
    if (mnt == "MNT-KHALIJFARSONLINE") {
        return "Khalij Fars Online";
    }
    if (mnt == "MEHVARMACHINE-MNT") {
        return "Mehvar Machine";
    }
    if (mnt == "MNT-HESABGAR") {
        return "Tak Net";
    }
    if (mnt == "ABNN-MNT") {
        return "Fanavaran Aban";
    }
    if (mnt ~ /^IR-PARVAZSYSTEM-[0-9]*-MNT$/) {
        return "Parvaz System";
    }
    if (mnt == "HK355-MNT") {
        return "Pishgaman";
    }
    if (mnt ~ /^IR-SEO-[0-9]*-MNT$/) {
        return "Boors DataCenter";
    }
    if (mnt == "MNT-MASOUD") {
        return "Byte ISP";
    }
    if (mnt ~ /^FANAVADP-LIR$/ || mnt == "MNT-FANAVA") {
        return "Fanava";
    }
    if (mnt ~ /^IR-JAVIDAN-[0-9]*-MNT$/) {
        return "Fanap";
    }
    if (mnt == "MNT-NGS-ROUTE" || mnt == "MNT-NGS-NOC") {
        return "Saba Net";
    }
    if (mnt == "DidEHBANNET") {
        return "Dideh Ban Net";
    }
    if (mnt == "MNT-RAEISI-RIPEMNT") {
        return "Badr Rayan";
    }
    if (mnt ~ /^IR-HOOR-[0-9]*-MNT$/) {
        return "Hoor";
    }
    if (mnt ~ /^IR-AYANDEH-[0-9]*-MNT$/ || mnt ~ /^MNT-IR-AYANDEH[0-9]*-[0-9]*$/) {
        return "Ertebatat Dourbord Fars";
    }
    if (mnt == "GILASSRAYANEH") {
        return "Fara Telecom";
    }
    if (mnt ~ /^IR-KAVOSHGAR[0-9]*-[0-9]*-MNT$/) {
        return "Kavoshgar Novin";
    }
    if (mnt == "MNT-RSPN") {
        return "Respina";
    }
    if (mnt ~ /^IR-AFRARASA-[0-9]*-MNT$/) {
        return "Afra Rasa";
    }
    if (mnt == "MXNT-MNT") {
        return "Max Net";
    }
    if (mnt == "IPM-MNT") {
        return "IPM";
    }
    if (mnt == "MNT-RASANA" || mnt == "MNT-DSA-HQ" || mnt ~ /^IR-EBTEKARANDISHAN-[0-9]*-MNT$/) {
        return "Shatel";
    }
    if (mnt == "REFAH-MNT" || mnt ~ /^SHN[0-9]*-MNT$/) {
        return "Refah Tech";
    }
    if (mnt == "MNT-FOROUD") {
        return "Saba Net";
    }
    if (mnt ~ /^IR-MIHAN-[0-9]*-MNT$/ || mnt == "MNT_MWH") {
        return "Mihan WebHost";
    }
    if (mnt ~ /^MNT-IR-PARSPARVA[0-9]*-[0-9]*$/ || mnt ~ /^IR-PARSPARVA-[0-9]*-MNT$/) {
        return "Yas Online";
    }
    if (mnt ~ /^IR-PEJVAK-[0-9]*-MNT$/) {
        return "Pejvak Net";
    }
    if (mnt == "MNT-ZENTEX") {
        return "Bahar Net";
    }
    if (mnt == "MNT-RDG-ADMIN" || mnt == "MNT-AURAUD") {
        return "Hiweb";
    }
    if (mnt == "MNT-HAJIAHMADI") {
        return "Aria Phone";
    }
    if (mnt == "HAMARASYSTEM-MNT") {
        return "Hamara";
    }
    if (mnt ~ /^MNT-SADP[0-9]*$/ || mnt ~ /^MNT-SADP[0-9]*-ROUTES$/) {
        return "Sea Net";
    }
    if (mnt ~ /^MNT-ASR[A-Z]$/) {
        return "Asre Ertebat";
    }
    if (mnt ~ /^IR-POOYA-[0-9]*-MNT$/) {
        return "Pooya Part o Gheshm";
    }
    if (mnt == "MNT-MANA") {
        return "Mana Net";
    }
    if (mnt == "DIDEHBANNET") {
        return "Dideh Ban Net";
    }
    if (mnt == "ASRETELECOM-MNT") {
        return "Asre Telecom";
    }
    if (mnt == "MNT-CWM") {
        return "Ertebat Gostar";
    }
    if (mnt == "AZMA-MNT") {
        return "Azma Group";
    }
    if (mnt == "SEPANTA-MNT") {
        return "Sepanta";
    }
    if (mnt ~ /^IR-NAKHLJONOOB-[0-9]*-MNT$/) {
        return "Nakhl";
    }
    if (mnt ~ /^IR-AZARAKHSH-[0-9]*-MNT$/) {
        return "Arya Oxin";
    }
    if (mnt == "SABZ-NETWORK") {
        return "Sabz Online";
    }
    if (mnt ~ /^IR-YAGHOOT-[0-9]*-MNT$/) {
        return "Yaghoot";
    }
    if (mnt ~ /^IR-EBTEKARANDISHAN-[0-9]*-MNT$/) {
        return "Parsian FCB";
    }
    if (mnt == "MNT-ARYASAT" || mnt == "ARYASAT" || mnt ~ /^ARYASAT-/) {
        return "Arya Sat";
    }
    if (mnt ~ /^MNT-IR-ASREDANESH-[0-9]*$/ || mnt ~ /^MNT-IR-ASREDANESH-[0-9]*-[0-9]*$/) {
        return "Asre Danesh";
    }
    if (mnt == "IRIB-MNT") {
        return "IRIB";
    }
    if (mnt == "JN-IP") {
        return "Mysha Net";
    }
    if (mnt == "WCD" || mnt ~ /^SUNINTERNET$/) {
        return "Sun Internet";
    }
    if (mnt == "MNT-SHAHRAD" || mnt == "MNT-AMIRSABET") {
        return "0-1.ir";
    }
    if (mnt == "FARZANEGAN-MNT") {
        return "Wenex";
    }
    if (mnt ~ /^IR-SHABAKIEH-[0-9]*-MNT$/) {
        return "Shabakieh";
    }
    if (mnt ~ /^IR-DAYAN-SHABAKE-GOSTAR-[0-9]*-MNT$/) {
        return "Dayan Shabake Gostar";
    }
    if (mnt ~ /^MNT-IR-PAPER-[0-9]*$/) {
        return "Dabco";
    }
    if (mnt ~ /^MNT-IR-MOEIN-DADOSETAD-[0-9]*$/) {
        return "Moein Dadosetad Golestan";
    }
    if (mnt ~ /^MNT-IR-KOSAR[0-9]*-[0-9]*$/) {
        return "Kosar Ghadir Agro Industrial Complex";
    }
    if (mnt == "HOS-GUN") {
        return "Hetzner Online";
    }
    if (mnt ~ /^IR-NOAVARAN[0-9]*-[0-9]*-MNT$/) {
        return "Noavaran System Sarv";
    }
    if (mnt ~ /^MNT-RAHANET$/) {
        return "Raha Net";
    }
    if (mnt == "MNT-SSAMAN") {
        return "Sys Tech";
    }
    if (mnt == "HOSTIRAN-MNT") {
        return "Host Iran";
    }
    if (mnt ~ /^IR-POSHTKAR-RAYANEH-KHARG-[0-9]*-MNT$/ || mnt == "GRAZ-AG-MNT") {
        return "Poshtkar Rayaneh Kharg";
    }
    if (mnt == "KAVOSHGARNOVIN-MNT" || mnt ~ /^IR-QESHMDEHKADEHERTEBATAT-[0-9]*-MNT$/) {
        return "Kavoshgar Novin";
    }
    if (mnt == "UTIC-MNT") {
        return "University of Tehran";
    }
    if (mnt == "PRIVAX-MNT") {
        return "Avax Software";
    }
    if (mnt == "APAKSERESHT-MNT") {
        return "Toloe Rayaneh Loghman";
    }
    if (mnt == "ABRARVAN") {
        return "Abr Arvan";
    }
    if (mnt ~ /^IR-FAVAPAYAM-[0-9]*-MNT$/) {
        return "FAVA";
    }
    if (mnt ~ /^IR-ASANPARDAKHT-[0-9]*-MNT$/) {
        return "Asan Pardakht";
    }
    if (mnt == "AFTAB-MNT" || mnt ~ /^MNT-IR-AFTAB-NETWORK-[0-9]*$/) {
        return "Aftab Net";
    }
    if (mnt ~ /^MNT-IR-UZNET-[0-9]*$/) {
        return "Uz Net";
    }
    if (mnt == "INSTITUTE-ISIRAN-MNT") {
        return "ISIRAN";
    }
    if (mnt ~ /^IR-CAFEBAZAAR-[0-9]*-MNT$/) {
        return "CafeBazaar";
    }
    if (mnt ~ /^IR-FANAVAZEH-[0-9]*-MNT$/) {
        return "Digikala";
    }
    if (mnt ~ /^IR-KHORSHIDNET-[0-9]*-MNT$/) {
        return "Khorshid Net";
    }
    if (mnt ~ /^IR-FCP-[0-9]*-MNT$/) {
        return "Ertebat Sabet Parsian";
    }
    if (mnt ~ /^IR-AUOS-[0-9]*-MNT$/) {
        return "Azad University";
    }
    if (mnt == "MNT-NRDC-FT") {
        return "Naji R&D";
    }
    if (mnt ~ /^IR-IRANIAN-NET-[0-9]*-MNT$/) {
        return "Iranian Net";
    }
    if (mnt == "MNT-PETIAK") {
        return "Petiak Net";
    }
    if (mnt == "MNT-ARP") {
        return "Asan Pardakht Parsian";
    }

    return "-";
}

function __whoisdb_get_iran_isp_from_owner(owner) {
    owner = toupper(owner);

    if (owner == "IR-DATAK-ADSL") {
        return "Datak";
    }
    if (owner == "SHABDIZ-TELECOM-NETWORK") {
        return "Shabdiz";
    }
    if (owner ~ /^IR-SUT-/) {
        return "Shahroud University of Technology";
    }
    if (owner ~ /^FANAPTELECOM-/) {
        return "Fanap";
    }
    if (owner == "IR-TAMINTELECOM" || owner ~ /^IR-TAMINTELECOM-/) {
        return "RighTel";
    }
    if (owner == "AFRARASA") {
        return "Afra Rasa";
    }
    if (owner ~ /^IR-BITA-/) {
        return "Bita Net";
    }
    if (owner ~ /-TCI$/ || owner == "TCE-NET" || owner == "TELECOMADSL" || owner == "TCI-NET" || owner ~ /TELECOMMUNICATION_COMPANY/ || owner ~ /^IR-TCI/) {
        return "Iran Telecommunication Company";
    }
    if (owner ~ /YASONLINE/) {
        return "Yas Online";
    }
    if (owner ~ /^IR-SHIRAZHAMYAR-/) {
        return "Hamyar Net";
    }
    if (owner == "ALBORZ-PARS") {
        return "Alborz Link";
    }
    if (owner == "ZENTEX") {
        return "Bahar Net";
    }
    if (owner == "ATRTINNETWORK") {
        return "Atrin Net";
    }
    if (owner == "RIGHTEL") {
        return "RighTel";
    }
    if (owner ~ /^SEFROYEK[-_]/ || owner ~ /^IR-SEFROYEKPARDAZENG-/) {
        return "0-1.ir";
    }
    if (owner == "TRLCO") {
        return "Webotel";
    }
    if (owner ~ /^INFRA-/) {
        return "Zirsakht";
    }
    if (owner ~ /^IR-REFATEC-/) {
        return "Refah Tech";
    }
    if (owner == "KHALIJ-FARS-ONLINE" || owner == "KHALIJ-FARS-ETELA-RESAN") {
        return "Khalij Fars Online";
    }
    if (owner == "CIS-IT-GROUP") {
        return "Shabakeh Gostar Sharyar";
    }
    if (owner == "HIRAD-ISP") {
        return "Hirad";
    }
    if (owner == "DPA") {
        return "Data Pardaz";
    }
    if (owner == "ARIAWEBCO") {
        return "Aria Web";
    }
    if (owner == "PARSIS-NET") {
        return "Parsis Net";
    }
    if (owner ~ /^IR-MOEIN-DADOSETAD-/) {
        return "Moein Dadosetad Golestan";
    }
    if (owner == "NIDC") {
        return "National Iranian Drilling Company";
    }
    if (owner ~ /^IR-DORNA/) {
        return "Uz Net";
    }
    if (owner ~ /^IR-SERVCO-AVAGOSTAR/) {
        return "Ava Gostar Sarv";
    }
    if (owner == "FARAHOOSH-SERVCO-SHIRAZ" || owner == "FARAHOOSHDENA-ADSL") {
        return "Farahoosh";
    }
    if (owner == "PARSIAN_BANK") {
        return "Parsian Bank";
    }
    if (owner ~ /^IR-FAVA/) {
        return "FAVA";
    }
    if (owner == "BEHPARDAKHT-MELLAT") {
        return "Behpardakht Mellat";
    }
    if (owner == "NOORIDC") {
        return "Noor Net";
    }
    if (owner == "VALAPAYAMFARDA") {
        return "Vala Payam Farda";
    }
    if (owner == "MAHANNET-TDLTE") {
        return "Mahan Net";
    }
    if (owner == "BUMSACIR") {
        return "Birjand University of Medical Sciences";
    }

    return "-";
}

function whoisdb_get_route_netmask(idx, route_netmask_index) {
    result_route_netmask = whoisdb_get_field(idx, "__ROUTE_NETMASK__", route_netmask_index);
    if (result_route_netmask != "") {
        return result_route_netmask;
    }

    result_route_netmask = _whoisdb_get_route_netmask(idx, route_netmask_index);
    if (result_route_netmask != "") {
        whoisdb_append_field(idx, "__ROUTE_NETMASK__", result_route_netmask);
    }

    return result_route_netmask;
}

function _whoisdb_get_route_netmask(idx, route_netmask_index) {
    _route_cidr = whoisdb_get_route(idx, route_netmask_index);
    if (_route_cidr != "") {
        return uncanonical_ip(cidr_netmask(_route_cidr));
    } 

    return "";
}

function whoisdb_get_route(idx, route_index) {
    result_route = whoisdb_get_field(idx, "__ROUTE__", route_index);
    if (result_route != "") {
        return result_route;
    }

    result_route = _whoisdb_get_route(idx, route_index);
    if (result_route != "") {
        whoisdb_append_field(idx, "__ROUTE__", result_route);
    }

    return result_route;
}

function _whoisdb_get_route(idx, route_index) {
    offset = 0;
    _route = whoisdb_get_field(idx, "route", route_index - offset);
    if (_route != "") {
        return _route;
    }
    offset = offset + whoisdb_get_field_length(idx, "route");

    _route_ip_start = whoisdb_get_ip_start(idx, route_index - offset);
    _route_ip_end = whoisdb_get_ip_end(idx, route_index - offset);
    if (_route_ip_start != "" && _route_ip_start != "000.000.000.000" && _route_ip_end != "" && _route_ip_end != "000.000.000.000") {
        return ip_range_to_cidr(_route_ip_start, _route_ip_end)
    }

    return "";
}

function whoisdb_get_route_length(idx) {
    return whoisdb_get_field_length(idx, "route") + _whoisdb_get_iprange_length(idx);
}

function whoisdb_get_netmask(idx, netmask_index) {
    result_netmask = whoisdb_get_field(idx, "__NETMASK__", netmask_index);
    if (result_netmask != "") {
        return result_netmask;
    }

    result_netmask = _whoisdb_get_netmask(idx, netmask_index);
    if (result_netmask != "") {
        whoisdb_append_field(idx, "__NETMASK__", result_netmask);
    }

    return result_netmask;
}

function _whoisdb_get_netmask(idx, netmask_index) {
    _netmask_cidr = whoisdb_get_cidr(idx, netmask_index);
    if (_netmask_cidr != "") {
        return uncanonical_ip(cidr_netmask(_netmask_cidr));
    } 

    return "";
}

function whoisdb_get_cidr(idx, cidr_index) {
    result_cidr = whoisdb_get_field(idx, "__CIDR__", cidr_index);
    if (result_cidr != "") {
        return result_cidr;
    }

    result_cidr = _whoisdb_get_cidr(idx, cidr_index);
    if (result_cidr != "") {
        whoisdb_append_field(idx, "__CIDR__", result_cidr);
    }

    return result_cidr;
}

function _whoisdb_get_cidr(idx, cidr_index) {
    _get_cidr_ip_start = whoisdb_get_ip_start(idx, cidr_index);
    _get_cidr_ip_end = whoisdb_get_ip_end(idx, cidr_index);

    if (_get_cidr_ip_start != "" && _get_cidr_ip_start != "000.000.000.000" && _get_cidr_ip_end != "" && _get_cidr_ip_end != "000.000.000.000") {
        return ip_range_to_cidr(_get_cidr_ip_start, _get_cidr_ip_end); 
    } 

    return "";
}

function whoisdb_get_asnumber(idx, asnumber_index) {
    result_asnumber = whoisdb_get_field(idx, "__ASNUMBER__", asnumber_index);
    if (result_asnumber != "") {
        return result_asnumber;
    }

    result_asnumber = _whoisdb_get_asnumber(idx, asnumber_index);
    if (result_asnumber != "") {
        whoisdb_append_field(idx, "__ASNUMBER__", result_asnumber);
    }

    return result_asnumber;
}

function _whoisdb_get_asnumber(idx, asnumber_index) {
    asnumber_list_length = 0;

    for (_whoisdb_get_asnumber_counter=1; _whoisdb_get_asnumber_counter<=whoisdb_get_field_length(idx, "origin"); _whoisdb_get_asnumber_counter++) {
        asnumber = whoisdb_get_field(idx, "origin", _whoisdb_get_asnumber_counter);
        asnumber_list_length = asnumber_list_length + 1;
        asnumber_list[asnumber_list_length] = asnumber;
    }

    if (asnumber_list_length == 0) {
        for (_whoisdb_get_asnumber_counter=1; _whoisdb_get_asnumber_counter<3;_whoisdb_get_asnumber_counter++) {
            ip_start = whoisdb_get_ip_start(idx, _whoisdb_get_asnumber_counter);
            ip_end = whoisdb_get_ip_end(idx, _whoisdb_get_asnumber_counter);

            if (ip_start != "" && ip_start != "000.000.000.000" && ip_end != "" && ip_end != "000.000.000.000") {
                cidr = ip_range_to_cidr(ip_start, ip_end); 

                if (cidr != "") {
                    asnumber_list_length = asnumber_list_length + 1;
                    asnumber_list[asnumber_list_length] = cidr;
                }
            } else {
                break;
            }
        }
    }

    if (asnumber_list_length == 0) {
        for (_whoisdb_get_asnumber_counter=1; _whoisdb_get_asnumber_counter<3;_whoisdb_get_asnumber_counter++) {
            ip_start = whoisdb_get_ip_start(idx, _whoisdb_get_asnumber_counter);
            ip_end = whoisdb_get_ip_end(idx, _whoisdb_get_asnumber_counter);

            if (ip_start != "" && ip_start != "000.000.000.000" && ip_end != "" && ip_end != "000.000.000.000") {
                asnumber_list_length = asnumber_list_length + 1;
                asnumber_list[asnumber_list_length] = uncanonical_ip(ip_start) "-" uncanonical_ip(ip_end);
            } else {
                break;
            }
        }
    }

    if (asnumber_list_length == 0) {
        return "";
    }

    for (asnumber_outer_sort_counter=1; asnumber_outer_sort_counter<=asnumber_list_length; asnumber_outer_sort_counter++) {
        asnumber = asnumber_list[asnumber_outer_sort_counter];

        for (asnumber_sort_counter=asnumber_outer_sort_counter; asnumber_sort_counter>=2; asnumber_sort_counter--) {
            next_asnumber_sort_counter = asnumber_sort_counter - 1;
            next_asnumber = asnumber_list[next_asnumber_sort_counter];

            if (asnumber < next_asnumber) {
                asnumber_list[next_asnumber_sort_counter] = asnumber;
                asnumber_list[asnumber_sort_counter] = next_asnumber;
            }
        }
    }

    return asnumber_list[asnumber_index];
}

### END DATABASE ###

function increment_counter(type, key, field, value) {
    _increment_counter(type, key, field, value);
    _increment_counter(type, key, "sum", value);
    _increment_counter(type, key, "count", 1);
    _increment_counter(type, "_", "sum", value);
    _increment_counter(type, "_", "count", 1);
}

function _ensure_counter_init() {
    if (stats_counter["_marked_"] == "") {
        stats_counter["_marked_"] = 1;

        stats_counter["count"] = 0;
        stats_counter["display"]["type"] = "none";
        stats_counter["display"]["show_sum"] = "on";
        stats_counter["display"]["show_count"] = "on";
    }
}

function _ensure_counter(type, key, field) {
    _ensure_counter_init();

    if (stats_counter["count"] == 0 || stats_counter["mark"][type] == "") {
        stats_counter["mark"][type] = 1;

        stats_counter["count"] = stats_counter["count"] + 1;
        stats_counter["types"][stats_counter["count"]] = type;
        stats_counter["type"][type]["count"] = 0;
    }

    if (stats_counter["type"][type]["count"] == 0 || stats_counter["type"][type]["mark"][key] == "") {
        stats_counter["type"][type]["mark"][key] = 1;
        
        stats_counter["type"][type]["count"] = stats_counter["type"][type]["count"] + 1;
        stats_counter["type"][type]["keys"][stats_counter["type"][type]["count"]] = key;
        stats_counter["type"][type]["key"][key]["count"] = 0;
    }

    if (stats_counter["type"][type]["key"][key]["count"] == 0 || stats_counter["type"][type]["key"][key]["mark"][field] == "") {
        stats_counter["type"][type]["key"][key]["mark"][field] = 1;

        stats_counter["type"][type]["key"][key]["count"] = stats_counter["type"][type]["key"][key]["count"] + 1;
        stats_counter["type"][type]["key"][key]["fields"][stats_counter["type"][type]["key"][key]["count"]] = field;
        stats_counter["type"][type]["key"][key]["field"][field] = 0;
    }
}

function set_counter_display_option(option, value) {
    _ensure_counter_init();
    stats_counter["display"][option] = value;
}

function _increment_counter(type, key, field, value) {
    _ensure_counter(type, key, field);
    stats_counter["type"][type]["key"][key]["field"][field] = stats_counter["type"][type]["key"][key]["field"][field] + value;
}

function sort_counter_key_decreasing(type, key, percent_mode) {
    stats_counter["type"][type]["key"][key]["sorted_count"] = 0;

    for (field_counter=1; field_counter<=stats_counter["type"][type]["key"][key]["count"]; field_counter++) {
        field = stats_counter["type"][type]["key"][key]["fields"][field_counter];
        value = stats_counter["type"][type]["key"][key]["field"][field];

        stats_counter["type"][type]["key"][key]["sorted_count"] = stats_counter["type"][type]["key"][key]["sorted_count"] + 1;
        stats_counter["type"][type]["key"][key]["sorted_fields"][stats_counter["type"][type]["key"][key]["sorted_count"]] = field;

        for (field_sort_counter=stats_counter["type"][type]["key"][key]["sorted_count"]; field_sort_counter>=2; field_sort_counter--) {
            next_field_sort_counter = field_sort_counter - 1;

            field_sort = stats_counter["type"][type]["key"][key]["sorted_fields"][field_sort_counter];
            next_field_sort = stats_counter["type"][type]["key"][key]["sorted_fields"][next_field_sort_counter];

            field_sort_value = stats_counter["type"][type]["key"][key]["field"][field_sort];
            next_field_sort_value = stats_counter["type"][type]["key"][key]["field"][next_field_sort];

            if (percent_mode == 1) {
                if (field_sort != "count") {
                    field_sort_value = (field_sort_value / stats_counter["type"][type]["key"]["_"]["field"]["sum"]) * 100;
                }
                if (next_field_sort != "count") {
                    next_field_sort_value = (next_field_sort_value / stats_counter["type"][type]["key"]["_"]["field"]["sum"]) * 100;
                }
            }

            if ((field_sort == "sum" || (field_sort == "count" && next_field_sort != "sum") || field_sort_value > next_field_sort_value) && next_field_sort != "sum" && (next_field_sort != "count" || field_sort == "sum")) {
                stats_counter["type"][type]["key"][key]["sorted_fields"][field_sort_counter] = next_field_sort;
                stats_counter["type"][type]["key"][key]["sorted_fields"][next_field_sort_counter] = field_sort;
            }
        }
    }

    for (field_counter=1; field_counter<=stats_counter["type"][type]["key"][key]["count"]; field_counter++) {
        stats_counter["type"][type]["key"][key]["fields"][field_counter] = stats_counter["type"][type]["key"][key]["sorted_fields"][field_counter];
    }

    delete stats_counter["type"][type]["key"]["key"]["sorted_count"];
    delete stats_counter["type"][type]["key"]["key"]["sorted_fields"];
}

function sort_counter_type_decreasing_on_field(type, field) {
    stats_counter["type"][type]["sorted_count"] = 0;

    sort_type_percent_mode = 0;
    if (field ~ /\s*%\s*$/) {
        sort_type_percent_mode = 1;
        sub(/\s*%\s*$/, "", field);
    }

    for (key_counter=1; key_counter<=stats_counter["type"][type]["count"]; key_counter++) {
        key = stats_counter["type"][type]["keys"][key_counter];

        sort_counter_key_decreasing(type, key, sort_type_percent_mode);

        stats_counter["type"][type]["sorted_count"] = stats_counter["type"][type]["sorted_count"] + 1;
        stats_counter["type"][type]["sorted_keys"][stats_counter["type"][type]["sorted_count"]] = key;

        for (key_sort_counter=stats_counter["type"][type]["sorted_count"]; key_sort_counter>=2; key_sort_counter--) {
            next_key_sort_counter = key_sort_counter - 1;

            key_sort = stats_counter["type"][type]["sorted_keys"][key_sort_counter];
            next_key_sort = stats_counter["type"][type]["sorted_keys"][next_key_sort_counter];

            key_sort_value = stats_counter["type"][type]["key"][key_sort]["field"][field];
            next_key_sort_value = stats_counter["type"][type]["key"][next_key_sort]["field"][field];

            if (sort_type_percent_mode == 1) {
                key_sort_value = (key_sort_value / stats_counter["type"][type]["key"][key_sort]["field"]["sum"]) * 100;
                next_key_sort_value = (next_key_sort_value / stats_counter["type"][type]["key"][next_key_sort]["field"]["sum"]) * 100;
            }

            if (key_sort_value > next_key_sort_value) {
                stats_counter["type"][type]["sorted_keys"][key_sort_counter] = next_key_sort;
                stats_counter["type"][type]["sorted_keys"][next_key_sort_counter] = key_sort;
            }
        }
    }

    for (key_counter=1; key_counter<=stats_counter["type"][type]["count"]; key_counter++) {
        stats_counter["type"][type]["keys"][key_counter] = stats_counter["type"][type]["sorted_keys"][key_counter];
    }

    delete stats_counter["type"][type]["sorted_count"];
    delete stats_counter["type"][type]["sorted_keys"];
}

function sort_counter_type_decreasing(type) {
    sort_counter_type_decreasing_on_field(type, "sum");
}

function aggregate_counter_type_using(type, fn) {
    if (fn == "sum" || fn == "count" || fn == "SUM" || fn == "COUNT") {
        _ensure_counter(type, "_", fn);
        return stats_counter["type"][type]["key"]["_"]["field"][fn];
    }
    if (fn ~ /^\s*sum\s*[\(].*[\)]\s*$/ || fn ~ /^\s*SUM\s*[\(].*[\)]\s*$/) {
        aggregate_field = fn;
        sub(/^\s*sum\s*[\(]\s*/, "", aggregate_field);
        sub(/^\s*SUM\s*[\(]\s*/, "", aggregate_field);
        sub(/\s*[\)]\s*$/, "", aggregate_field);

        aggregate_result = 0;
        aggregate_percent_mode = 0;

        if (aggregate_field ~ /\s*%\s*$/) {
            aggregate_percent_mode = 1;
            sub(/\s*%\s*$/, "", aggregate_field);
        }

        for (aggregate_key_counter=1; aggregate_key_counter<=stats_counter["type"][type]["count"]; aggregate_key_counter++) {
            aggregate_key = stats_counter["type"][type]["keys"][aggregate_key_counter];
            aggregate_value = stats_counter["type"][type]["key"][aggregate_key]["field"][aggregate_field];
            aggregate_result = aggregate_result + aggregate_value;
        }

        if (aggregate_percent_mode == 1) {
            aggregate_result = (aggregate_result / stats_counter["type"][type]["key"]["_"]["field"]["sum"]) * 100;
        }

        return aggregate_result;
    }
    print "ERROR: Undefined aggregate function: [" fn "]";
    return "";
}

function sort_counter_decreasing_using(fn) {
    stats_counter["sorted_count"] = 0;

    sort_type_crit = fn;
    if (sort_type_crit ~ /^\s*sum\s*[\(].*[\)]\s*$/ || sort_type_crit ~ /^\s*SUM\s*[\(].*[\)]\s*$/) {
        sub(/^\s*sum\s*[\(]\s*/, "", sort_type_crit);
        sub(/^\s*SUM\s*[\(]\s*/, "", sort_type_crit);
        sub(/\s*[\)]\s*$/, "", sort_type_crit);
    }

    for (type_counter=1; type_counter<=stats_counter["count"]; type_counter++) {
        type = stats_counter["types"][type_counter];

        sort_counter_type_decreasing_on_field(type, sort_type_crit);

        stats_counter["sorted_count"] = stats_counter["sorted_count"] + 1;
        stats_counter["sorted_types"][stats_counter["sorted_count"]] = type;

        for (type_sort_counter=stats_counter["sorted_count"]; type_sort_counter>=2; type_sort_counter--) {
            next_type_sort_counter = type_sort_counter - 1;

            type_sort = stats_counter["sorted_types"][type_sort_counter];
            next_type_sort = stats_counter["sorted_types"][next_type_sort_counter];

            type_sort_value = aggregate_counter_type_using(type_sort, fn);
            next_type_sort_value = aggregate_counter_type_using(next_type_sort, fn);

            if (type_sort_value > next_type_sort_value) {
                stats_counter["sorted_types"][type_sort_counter] = next_type_sort;
                stats_counter["sorted_types"][next_type_sort_counter] = type_sort;
            }
        }
    }

    for (type_counter=1; type_counter<=stats_counter["count"]; type_counter++) {
        stats_counter["types"][type_counter] = stats_counter["sorted_types"][type_counter];
    }

    delete stats_counter["sorted_count"];
    delete stats_counter["sorted_types"];
}

function sort_counter_decreasing() {
    sort_counter_decreasing_using("sum");
}

function report_counter_txt() {
    if (stats_counter["_marked_"] == "") {
        stats_counter["_marked_"] = 1;

        stats_counter["count"] = 0;
    }

    for (type_counter=1; type_counter<=stats_counter["count"]; type_counter++) {
        type = stats_counter["types"][type_counter];

        print "[" type "]";
        print "";

        for (key_counter=1; key_counter<=stats_counter["type"][type]["count"]; key_counter++) {
            key = stats_counter["type"][type]["keys"][key_counter];

            if (key != "_") {
                print "\t<" key ">";

                for (field_counter=1; field_counter<=stats_counter["type"][type]["key"][key]["count"]; field_counter++) {
                    field = stats_counter["type"][type]["key"][key]["fields"][field_counter];

                    if ((field != "sum" || stats_counter["display"]["show_sum"] != "off") && (field != "count" || stats_counter["display"]["show_count"] != "off")) {
                        value = stats_counter["type"][type]["key"][key]["field"][field];

                        if (field != "count" && stats_counter["display"]["type"] == "percent") {
                            value = "" ((value / stats_counter["type"][type]["key"][key]["field"]["sum"]) * 100) "%";
                        }

                        print "\t  " field ": " value;
                    }
                }
            }
        }

        print "";
        print "-----------------";
        print "";
    }

    print "";
    print "";
}

/^\s*SORT\s+DESC\s*$/ {
    sort_counter_decreasing();
}

/^\s*SORT\s+DESC\s+USING\s+.*$/ {
    fn = $0;
    sub(/\s*SORT\s+DESC\s+USING\s+/, "", fn);
    sub(/\s*$/, "", fn);
    
    sort_counter_decreasing_using(fn);
}

/^\s*REPORT\s*$/ {
    report_counter_txt();
}

/^\s*DISPLAY\s+PERCENT\s*$/ {
    set_counter_display_option("type", "percent");
}

/^\s*DISPLAY\s+SHOW\s+SUM\s+OFF\s*$/ {
    set_counter_display_option("show_sum", "off");
}

/^\s*DISPLAY\s+SHOW\s+SUM\s+ON\s*$/ {
    set_counter_display_option("show_sum", "on");
}

/^\s*DISPLAY\s+SHOW\s+COUNT\s+OFF\s*$/ {
    set_counter_display_option("show_count", "off");
}

/^\s*DISPLAY\s+SHOW\s+COUNT\s+ON\s*$/ {
    set_counter_display_option("show_count", "on");
}

/^\s*INCREMENT\s+[^,]+\s*,\s*[^,]+\s*,\s*[^,]+\s*,\s*[0-9]+\s*$/ {
    line = $0;
    sub(/^\s*INCREMENT\s*/, "", line)
    sub(/\s*$/, "", line);
    split(line,parts,",")

    for (i=1; i<=4; i++) {
        sub(/^\s*/, "", parts[i]);
        sub(/\s*$/, "", parts[i]);
    }

    increment_counter(parts[1], parts[2], parts[3], int(parts[4]));
}

/^\s*((ONE)|(COUNTRY)|(ISP)|(ASNUMBER)|(CIDR)|(NETMASK)|(ROUTE)|(ROUTING_NETMASK))(\s*((,\s*ONE)|(,\s*COUNTRY)|(,\s*ISP)|(,\s*ASNUMBER)|(,\s*CIDR)|(,\s*NETMASK)|(,\s*ROUTE)|(,\s*ROUTING_NETMASK)))*\s*[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*(\s\s*.*)?$/ {
    if (NR % 100 == 0) {
        whoisdb_save();
    }

    requested_fields_length = 0;
    select_one = 0;

    line = $0;
    for (;;) {
        if (line ~ /^\s*COUNTRY\s*/) {
            requested_fields_length = requested_fields_length + 1;
            requested_fields[requested_fields_length] = "country";
            sub(/^\s*COUNTRY\s*(,\s*)?/, "", line);
        } else if (line ~ /^\s*ISP\s*/) {
            requested_fields_length = requested_fields_length + 1;
            requested_fields[requested_fields_length] = "isp";
            sub(/^\s*ISP\s*(,\s*)?/, "", line);
        } else if (line ~ /^\s*ASNUMBER\s*/) {
            requested_fields_length = requested_fields_length + 1;
            requested_fields[requested_fields_length] = "asnumber";
            sub(/^\s*ASNUMBER\s*(,\s*)?/, "", line);
        } else if (line ~ /^\s*CIDR\s*/) {
            requested_fields_length = requested_fields_length + 1;
            requested_fields[requested_fields_length] = "cidr";
            sub(/^\s*CIDR\s*(,\s*)?/, "", line);
        } else if (line ~ /^\s*NETMASK\s*/) {
            requested_fields_length = requested_fields_length + 1;
            requested_fields[requested_fields_length] = "netmask";
            sub(/^\s*NETMASK\s*(,\s*)?/, "", line);
        } else if (line ~ /^\s*ROUTE\s*/) {
            requested_fields_length = requested_fields_length + 1;
            requested_fields[requested_fields_length] = "route";
            sub(/^\s*ROUTE\s*(,\s*)?/, "", line);
        } else if (line ~ /^\s*ROUTING_NETMASK\s*/) {
            requested_fields_length = requested_fields_length + 1;
            requested_fields[requested_fields_length] = "route_netmask";
            sub(/^\s*ROUTING_NETMASK\s*(,\s*)?/, "", line);
        } else if (line ~ /^\s*ONE\s*/) {
            select_one = 1;
            sub(/^\s*ONE\s*(,\s*)?/, "", line);
        } else {
            break;
        }
    }

    remainder_idx = match(line, /\s\s*.*$/);
    if (remainder_idx != 0) {
        ip = substr(line, 1, remainder_idx - 1);
        remainder = substr(line, remainder_idx);
    } else {
        ip = line;
        remainder = "";
    }

    sub(/^\s*/, "", remainder);
    sub(/^\s*/, "", ip);
    sub(/\s*$/, "", remainder);
    sub(/\s*$/, "", ip);

    finished_fields_marker["cidr"] = 0
    finished_fields_marker["asnumber"] = 0
    finished_fields_marker["netmask"] = 0
    finished_fields_marker["route"] = 0
    finished_fields_marker["route_netmask"] = 0

    idx = whoisdb_lookup(ip);
    if (idx == 0) {
        print "ERROR: could not fetch [" ip "] at [NR=" NR "]";
    } else {
        finished_fields = 0;
        for (data_index_counter=1; (select_one == 1 && data_index_counter == 1) || (select_one == 0 && finished_fields < requested_fields_length); data_index_counter++) {
            for (requested_field_counter=1; requested_field_counter<=requested_fields_length; requested_field_counter++) {
                requested_field = requested_fields[requested_field_counter];
                if (requested_field == "country") {
                    country = whoisdb_get_country(idx);
                    if (country == "") {
                        print "ERROR: could not find country for [" ip "] at [NR=" NR "] (index=" idx ") matching ORIGIN=[" whoisdb_get_origin(idx) "] RECORD_IDX=[" idx "]";
                        country = "(UNKNOWN)";
                    }

                    if (data_index_counter > 1) {
                        finished_fields = finished_fields + 1;
                    }

                    result_row[requested_field_counter] = country;
                } else if (requested_field == "isp") {
                    isp = whoisdb_get_iran_isp(idx);
                    if (isp == "") {
                        country = whoisdb_get_country(idx);
                        if (country == "IR") {
                            print "ERROR: could not find isp for [" ip "] at [NR=" NR "] (index=" idx ") matching ORIGIN=[" whoisdb_get_origin(idx) "] RECORD_IDX=[" idx "]";
                        } else {
                            print "WARN: could not find non-IR isp for [" ip "] at [NR=" NR "] (index=" idx ") matching ORIGIN=[" whoisdb_get_origin(idx) "] RECORD_IDX=[" idx "]";
                        }
                        isp = "(UNKNOWN)";
                    }

                    if (data_index_counter > 1) {
                        finished_fields = finished_fields + 1;
                    }

                    result_row[requested_field_counter] = isp;
                } else if (requested_field == "asnumber") {
                    asnumber = whoisdb_get_asnumber(idx, data_index_counter);
                    if (asnumber == "") {
                        if (finished_fields_marker["asnumber"] != 1) {
                            finished_fields = finished_fields + 1;
                            finished_fields_marker["asnumber"] = 1;
                        }
                        if (data_index_counter == 1) {
                            print "ERROR: could not find asnumber for [" ip "] at [NR=" NR "] (index=" idx ") matching ORIGIN=[" whoisdb_get_origin(idx) "] RECORD_IDX=[" idx "]";
                        }
                        asnumber = "(UNKNOWN)";
                    }

                    result_row[requested_field_counter] = asnumber;
                } else if (requested_field == "cidr") {
                    cidr = whoisdb_get_cidr(idx, data_index_counter);
                    if (cidr == "") {
                        if (finished_fields_marker["cidr"] != 1) {
                            finished_fields = finished_fields + 1;
                            finished_fields_marker["cidr"] = 1;
                        }
                        if (data_index_counter == 1) {
                            print "ERROR: could not find CIDR for [" ip "] at [NR=" NR "] (index=" idx ") matching ORIGIN=[" whoisdb_get_origin(idx) "] RECORD_IDX=[" idx "]";
                        }
                        cidr = "(UNKNOWN)";
                    }

                    result_row[requested_field_counter] = cidr;
                } else if (requested_field == "netmask") {
                    netmask_cidr = whoisdb_get_cidr(idx, data_index_counter);
                    if (netmask_cidr != "") {
                        netmask = uncanonical_ip(cidr_netmask(netmask_cidr));
                    } else {
                        netmask = "";
                    }
                    if (netmask == "") {
                        if (finished_fields_marker["netmask"] != 1) {
                            finished_fields = finished_fields + 1;
                            finished_fields_marker["netmask"] = 1;
                        }
                        if (data_index_counter == 1) {
                            print "ERROR: could not find netmask for [" ip "] at [NR=" NR "] (index=" idx ") matching ORIGIN=[" whoisdb_get_origin(idx) "] RECORD_IDX=[" idx "]";
                        }
                        netmask = "(UNKNOWN)";
                    }

                    result_row[requested_field_counter] = netmask;
                } else if (requested_field == "route") {
                    route = whoisdb_get_route(idx, data_index_counter);
                    if (route == "") {
                        if (finished_fields_marker["route"] != 1) {
                            finished_fields = finished_fields + 1;
                            finished_fields_marker["route"] = 1;
                        }
                        if (data_index_counter == 1) {
                            print "ERROR: could not find route for [" ip "] at [NR=" NR "] (index=" idx ") matching ORIGIN=[" whoisdb_get_origin(idx) "] RECORD_IDX=[" idx "]";
                        }
                        route = "(UNKNOWN)";
                    }

                    result_row[requested_field_counter] = route;
                } else if (requested_field == "route_netmask") {
                    route_netmask = whoisdb_get_route_netmask(idx, data_index_counter);
                    if (route_netmask == "") {
                        if (finished_fields_marker["route_netmask"] != 1) {
                            finished_fields = finished_fields + 1;
                            finished_fields_marker["route_netmask"] = 1;
                        }
                        if (data_index_counter == 1) {
                            print "ERROR: could not find route netmask for [" ip "] at [NR=" NR "] (index=" idx ") matching ORIGIN=[" whoisdb_get_origin(idx) "] RECORD_IDX=[" idx "]";
                        }
                        route_netmask = "(UNKNOWN)";
                    }

                    result_row[requested_field_counter] = route_netmask;
                }
            }

            out_line = ip;
            for (requested_field_counter=1; requested_field_counter<=requested_fields_length; requested_field_counter++) {
                out_line = (out_line "," result_row[requested_field_counter]);
            }

            if (remainder != "") {
                out_line = (out_line "," remainder);
            }

            if (finished_fields < requested_fields_length) {
                print out_line;
            }
        }
    }
}

/^REBUILD [0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*$/ {
    WHOISDB["is_rebuild"] = 1;

    ip = $0;
    sub(/^REBUILD /, "", ip);

    if (NR % 100 == 0) {
        whoisdb_save();
        
        print "";
        print ">> [NR=" NR "]";
        print "";

        set_counter_display_option("type", "none");
        set_counter_display_option("show_sum", "off");
        set_counter_display_option("show_count", "off");
        sort_counter_decreasing();
        report_counter_txt();
    }
    idx = whoisdb_lookup(ip);
    if (idx == 0) {
        print "ERROR: could not fetch [" ip "] at [NR=" NR "]";
    } else {
        asnumber = whoisdb_get_asnumber(idx, 1);
        if (asnumber == "") {
            print "ERROR: could not find asnumber for [" ip "] at [NR=" NR "] matching ORIGIN=[" whoisdb_get_origin(idx) "]";
        }
        for (asnumber_index=2; whoisdb_get_asnumber(idx, asnumber_index) != ""; asnumber_index++) {
        }

        netmask = whoisdb_get_netmask(idx, 1);
        if (asnumber == "") {
            print "ERROR: could not find netmask for [" ip "] at [NR=" NR "] matching ORIGIN=[" whoisdb_get_origin(idx) "]";
        }
        for (netmask_index=2; whoisdb_get_netmask(idx, netmask_index) != ""; netmask_index++) {
        }

        cidr = whoisdb_get_cidr(idx, 1);
        if (asnumber == "") {
            print "ERROR: could not find CIDR for [" ip "] at [NR=" NR "] matching ORIGIN=[" whoisdb_get_origin(idx) "]";
        }
        for (cidr_index=2; whoisdb_get_cidr(idx, cidr_index) != ""; cidr_index++) {
        }

        route = whoisdb_get_route(idx, 1)
        if (route == "") {
            print "ERROR: could not find route for [" ip "] at [NR=" NR "] [idx=" idx "] matching ORIGIN=[" whoisdb_get_origin(idx) "]";
            route = "[UNKNOWN]";
        }
        for (route_index=2; whoisdb_get_route(idx, route_index) != ""; route_index++) {
        }

        route_netmask = whoisdb_get_route_netmask(idx, 1);
        if (asnumber == "") {
            print "ERROR: could not find route_netmask for [" ip "] at [NR=" NR "] matching ORIGIN=[" whoisdb_get_origin(idx) "]";
        }
        for (route_netmask_index=2; whoisdb_get_route_netmask(idx, route_netmask_index) != ""; route_netmask_index++) {
        }

        country = whoisdb_get_country(idx);
        if (country == "") {
            print "ERROR: could not find country for [" ip "] at [NR=" NR "] [idx=" idx "] matching ORIGIN=[" whoisdb_get_origin(idx) "]";
            country = "[UNKNOWN]";
        } 

        if (country == "IR") {
            print "INFO: IR_IP=" ip;
            isp = whoisdb_get_iran_isp(idx);

            if (isp == "") {
                for (i=1; i<=whoisdb_get_field_length(idx, "mnt-by"); i++) {
                    mnt = whoisdb_get_field(idx, "mnt-by", i);
                    if (toupper(mnt) ~ /^AS[0-9]*-MNT$/ || mnt == "RIPE-NCC-HM-MNT") {
                        continue;
                    }

                    increment_counter("IR-UNKNOWN-MNT", mnt, "value", 1);

                    for (j=1; j<=whoisdb_get_owner_length(idx);j++) {
                        owner = whoisdb_get_owner(idx, j);
                        increment_counter("IR-UNKNOWN-MNT-OWNER", mnt ":" owner, "value", 1);
                    }
                }
                for (j=1; j<=whoisdb_get_owner_length(idx);j++) {
                    owner = whoisdb_get_owner(idx, j);
                    increment_counter("IR-UNKOWN-OWNER", owner, "value", 1);
                }
            }
 
            if (isp == "") {
                organization = whoisdb_get_owner(idx, 1);
                print "ERROR: could not find ISP for [" ip "] at [" NR "] ORIGIN=[" whoisdb_get_origin(idx) "]"; 
                isp = "(UNKNOWN)";
            } 

            increment_counter("IR-ISP", isp, "value", 1);
        }

        increment_counter("Country", country, "value", 1);
    }
}

END {
    if (WHOISDB["is_rebuild"] == 1) {
        set_counter_display_option("type", "none");
        set_counter_display_option("show_sum", "off");
        set_counter_display_option("show_count", "off");
        sort_counter_decreasing();
        report_counter_txt();
    }

    whoisdb_save();
}
