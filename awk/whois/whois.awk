BEGIN {
    whois_reload_db();
}

function whois_reload_db() {
    whois_records_length = 0;
    ignore_list_length = 0;
    whois_records_dirty = 0;

    while ((getline line < "whois.db") > 0) {
        whois_records_length = whois_records_length + 1;
        split(line, parts, "`")

        n = int(parts[1]);
        fields_length = 0;
        for (i=2; i<=(n*2)+1; i+=2) {
            field = parts[i];
            value = parts[i+1];

            fields_length = fields_length + 1;
            whois_records[whois_records_length]["fields"][fields_length] = field;
            whois_records[whois_records_length]["values"][field] = value;
        }

        whois_records[whois_records_length]["fields_length"] = fields_length;
    }

    close("whois.db");

    while ((getline line < "ignore.txt") > 0) {
        sub(/^\s*/,"",line);
        sub(/\s*$/,"",line);
        ignore_list_length = ignore_list_length + 1;
        ignore_list[ignore_list_length] = line;
    }

    close("ignore.txt");

    whois_records_start_ips_length = 0;
    for (rebuild_counter=1; rebuild_counter<=whois_records_length; rebuild_counter++) {
        start = get_whois_record_ip_start_by_index(rebuild_counter);
        whois_records_start_ips_length = whois_records_start_ips_length + 1;
        whois_records_start_ips[whois_records_start_ips_length] = start;
    }
}

function decimal_to_boolean(num) {
    result = "";

    while (num > 1) {
        result = ((num % 2) result);
        num = int(num / 2);
    }

    result = (num result);

    return result;
}

function boolean_to_decimal(val) {
    split(val,parts,"");
    result = 0;
    for (i=1; parts[i]!=""; i++) {
        result = (result * 2) + int(parts[i]);
    }
    return int(result);
}

function fix_ip(ip) {
    split(ip,parts,".");
    result = sprintf("%03d.%03d.%03d.%03d",parts[1],parts[2],parts[3],parts[4]);
    return result;
}

function ip_to_boolean(ip) {
    split(ip,parts,".");
    for (i=1;i<=4;i++) {
        if (parts[i]=="") {
            part = "0";
        } else {
            part = decimal_to_boolean(int(parts[i]));
        }
        part = sprintf("%08s", part);
        for (j=1;j<=8;j++) {
            sub(/ /,"0",part);
        }
        result_parts[i] = part;
    }
    return sprintf("%s%s%s%s", result_parts[1], result_parts[2], result_parts[3], result_parts[4]);
}

function boolean_to_ip(val) {
    boolean_to_ip_parts[1] = boolean_to_decimal(substr(val, 1, 8));
    boolean_to_ip_parts[2] = boolean_to_decimal(substr(val, 9, 8));
    boolean_to_ip_parts[3] = boolean_to_decimal(substr(val, 17, 8));
    boolean_to_ip_parts[4] = boolean_to_decimal(substr(val, 25, 8));
    return sprintf("%d.%d.%d.%d", boolean_to_ip_parts[1], boolean_to_ip_parts[2], boolean_to_ip_parts[3], boolean_to_ip_parts[4]);
}

function boolean_and(left, right) {
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

function boolean_or(left, right) {
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

function cidr_low_bitmask(count) {
    result = "";
    for (i=1; i<=count; i++) {
        result = (result "1");
    }
    for (i=count; i<=32; i++) {
        result = (result "0");
    }
    return result;
}

function cidr_high_bitmask(count) {
    result = "";
    for (i=1; i<=count; i++) {
        result = (result "0");
    }
    for (i=count; i<=32; i++) {
        result = (result "1");
    }
    return result;
}

function cidr_start_ip(cidr) {
    idx = match(cidr,/\//);
    if (idx == 0) {
        return "";
    }

    ip = substr(cidr, 0, idx - 1);
    count = substr(cidr, idx + 1);

    sub(/^\s*/,"",ip);
    sub(/^\s*/,"",count);
    sub(/\s*$/,"",ip);
    sub(/\s*$/,"",count);

    count = int(count);

    return fix_ip(boolean_to_ip(boolean_and(ip_to_boolean(ip), cidr_low_bitmask(count))))
}

function cidr_end_ip(cidr) {
    idx = match(cidr,/\//);
    if (idx == 0) {
        return "";
    }

    ip = substr(cidr, 0, idx - 1);
    count = int(substr(cidr, idx + 1));

    return fix_ip(boolean_to_ip(boolean_or(ip_to_boolean(ip), cidr_high_bitmask(count))))
}

func parse_field(line) {
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

func parse_value(line) {
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

function discard_seperator(a_line) {
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

function fetch_whois(ip) {
    print "[fetching.. " ip "]";
    lines_length = 0;
    cache_file = "cache/" ip;
    read_cache_file_cmd = ("cat " cache_file);

    while (read_cache_file_cmd | getline line) {
        line = discard_seperator(line);

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
        cmd = ("whois " ip);

        print "[contacting whois..]";
        while (cmd | getline line) {
            line = discard_seperator(line);

            lines_length = lines_length + 1;
            lines[lines_length] = line;
        }
        close(line);
        close(cmd);

        for (i=1; i<=lines_length; i++) {
            print(lines[i]) >> cache_file;
        }
        close(cache_file);
    }

    fields_length = 0;
    whois_records_length = whois_records_length + 1;

    for (i=1; i<=lines_length; i++) {
        if (lines[i] ~ /temporary unable to query/) {
            print "ERROR: [TEMPORARY UNABLE TO QUERY '" ip "']"
            whois_records_length = whois_records_length - 1;
            return "";
        }

        field = parse_field(lines[i]);
        value = parse_value(lines[i]);

        if (field != "" && value != "") {
            fields_length = fields_length + 1;
            fields[fields_length] = field;
            values[field] = value;

            whois_records[whois_records_length]["fields"][fields_length] = field;
            whois_records[whois_records_length]["values"][field] = value;
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

                    fields_length = fields_length + 1;
                    fields[fields_length] = "NetRange";
                    values["NetRange"] = range;

                    whois_records[whois_records_length]["fields"][fields_length] = "NetRange";
                    whois_records[whois_records_length]["values"]["NetRange"] = range;

                    fields_length = fields_length + 1;
                    fields[fields_length] = "OrgName";
                    values["OrgName"] = owner;

                    whois_records[whois_records_length]["fields"][fields_length] = "OrgName";
                    whois_records[whois_records_length]["values"]["OrgName"] = owner;
                }
            }
        }
    }

    if (fields_length == 0) {
        print "ERROR: UNABLE TO EXTRACT WHOIS FIELDS";
        whois_records_length = whois_records_length - 1;

        for (i=1; i<=lines_length; i++) {
            print "ERROR: DBG: [" i "]: " lines[i];
        }

        return "";
    }

    whois_records[whois_records_length]["fields_length"] = fields_length;

    if (fields_length > 0) {
        whois_records_dirty = 1;

        out_line = "" fields_length;
        for (i=1; i<= fields_length; i++) {
            out_line = (out_line "`" fields[i] "`" values[fields[i]]);
        }
        print(out_line) >> "whois.db";
        close("whois.db");
    }

    print "[ fetch done ]";
}

function get_whois_length() {
    return whois_records_length;
}

function get_whois_record_by_index(idx, field) {
    return whois_records[idx]["values"][field];
}

function _get_whois_ip_range_by_index(idx) {
    range = get_whois_record_by_index(idx, "NetRange");
    if (range != "") {
        return range;
    }

    range = get_whois_record_by_index(idx, "inetnum");
    if (range != "") {
        return range;
    }

    range = get_whois_record_by_index(idx, "IPv4 Address");
    if (range != "") {
        return range;
    }

    range = get_whois_record_by_index(idx, "Network Number");
    if (range != "") {
        return range;
    }

    range = get_whois_record_by_index(idx, "CIDR");
    if (range != "") {
        return range;
    }

    return "";
}

function get_whois_record_ip_start_by_index(idx) {
    result_record_ip_start = get_whois_record_by_index(idx, "__START_IP__");
    if (result_record_ip_start != "") {
        return result_record_ip_start;
    }

    result_record_ip_start = _get_whois_record_ip_start_by_index(idx);
    if (result_record_ip_start != "") {
        whois_append_field(idx, "__START_IP__", result_record_ip_start);
    }
    return result_record_ip_start;
}

function _get_whois_record_ip_start_by_index(idx) {
    _get_whois_record_ip_start_range = _get_whois_ip_range_by_index(idx);

    if (_get_whois_record_ip_start_range ~ /[0-9][0-9]*(\.[0-9][0-9]*(\.[0-9][0-9]*(\.[0-9][0-9]*)?)?)?\s*\/\s*[0-9][0-9]*/) {
        ip_start = cidr_start_ip(_get_whois_record_ip_start_range);
        ip_end = cidr_end_ip(_get_whois_record_ip_start_range);

        if (ip_start != "" && ip_end != "" && ip_start != "000.000.000.000" && ip_end != "000.000.000.000") {
            return ip_start;
        }

        print "ERROR: (1) PARSING ip_start [" _get_whois_record_ip_start_range "] FOR INDEX [" idx "] FROM [" _get_whois_record_ip_start_range "]";
        return "";
    }

    if (_get_whois_record_ip_start_range !~ /[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\s*-\s*[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*/) {
        print "ERROR: (2) FAILED TO PARSE IP ip_start FOR IDX=" idx " FROM [" _get_whois_record_ip_start_range "]";
        return "";
    }

    split(_get_whois_record_ip_start_range, _get_whois_ip_ranges_start_ip_ranges, "-");
    sub(/^\s*/, "", _get_whois_ip_ranges_start_ip_ranges[1]);
    sub(/^\s*/, "", _get_whois_ip_ranges_start_ip_ranges[2]);
    sub(/\s*$/, "", _get_whois_ip_ranges_start_ip_ranges[1]);
    sub(/\s*$/, "", _get_whois_ip_ranges_start_ip_ranges[2]);

    if (_get_whois_ip_ranges_start_ip_ranges[1] != "" && _get_whois_ip_ranges_start_ip_ranges[2] != "") {
        _get_whois_record_ip_start_ip_ranges_start = fix_ip(_get_whois_ip_ranges_start_ip_ranges[1]);
        _get_whois_record_ip_start_ip_ranges_end = fix_ip(_get_whois_ip_ranges_start_ip_ranges[2]);

        if (_get_whois_record_ip_start_ip_ranges_start != "" && _get_whois_record_ip_start_ip_ranges_end != "" && _get_whois_record_ip_start_ip_ranges_start != "000.000.000.000" && _get_whois_record_ip_start_ip_ranges_end != "000.000.000.000") {
            return _get_whois_record_ip_start_ip_ranges_start;
        }
    }

    print "ERROR: (3) FAILED TO PARSE ip_start IP RANGE FOR IDX=" idx " FROM " _get_whois_record_ip_start_range;
    return "";
}

function get_whois_record_ip_end_by_index(idx) {
    result_record_ip_end = get_whois_record_by_index(idx, "__IP_END__");
    if (result_record_ip_end != "") {
        return result_record_ip_end;
    }

    result_record_ip_end = _get_whois_record_ip_end_by_index(idx);
    if (result_record_ip_end != "") {
        whois_append_field(idx, "__IP_END__", result_record_ip_end);
    }

    return result_record_ip_end;
}

function _get_whois_record_ip_end_by_index(idx) {
    range = _get_whois_ip_range_by_index(idx);

    if (range ~ /[0-9][0-9]*(\.[0-9][0-9]*(\.[0-9][0-9]*(\.[0-9][0-9]*)?)?)?\s*\/\s*[0-9][0-9]*/) {
        ip_start = cidr_start_ip(range);
        ip_end = cidr_end_ip(range);

        if (ip_start != "" && ip_end != "" && ip_start != "000.000.000.000" && ip_end != "000.000.000.000") {
            return ip_end;
        }

        print "ERROR: (4) PARSING [" range "] FOR INDEX [" idx "] FROM [" range "]";
        return "";
    }

    if (range !~ /[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\s*-\s*[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*/) {
        print "ERROR: (5) FAILED TO PARSE IP RANGE FOR IDX=" idx " FROM [" range "]";
        return "";
    }

    split(range, ip_ranges, "-");
    sub(/^\s*/, "", ip_ranges[1]);
    sub(/^\s*/, "", ip_ranges[2]);
    sub(/\s*$/, "", ip_ranges[1]);
    sub(/\s*$/, "", ip_ranges[2]);

    if (ip_ranges[1] != "" && ip_ranges[2] != "") {
        ip_start = fix_ip(ip_ranges[1]);
        ip_end = fix_ip(ip_ranges[2]);

        if (ip_start != "" && ip_end != "" && ip_start != "000.000.000.000" && ip_end != "000.000.000.000") {
            return ip_end;
        }
    }

    print "ERROR: (6) FAILED TO PARSE IP RANGE FOR IDX=" idx " FROM [" range "]";
    return "";
}

function get_whois_phone_by_index(idx) {
    result_phone = get_whois_record_by_index(idx, "__PHONE__");
    if (result_phone != "") {
        return result_phone;
    }

    result_phone = _get_whois_phone_by_index(idx);
    if (result_phone != "") {
        whois_append_field(idx, "__PHONE__", result_phone);
    }

    return result_phone;
}

function _get_whois_phone_by_index(idx) {
    result = get_whois_record_by_index(idx, "Phone");
    if (result != "") {
        return result;
    }

    return "";
}

function get_whois_owner_by_index(idx) {
    result_owner = get_whois_record_by_index(idx, "__OWNER__");
    if (result_owner != "") {
        return result_owner;
    }

    result_owner = _get_whois_owner_by_index(idx);
    if (result_owner != "") {
        whois_append_field(idx, "__OWNER__", result_owner);
    }

    return result_owner;
}

function _get_whois_owner_by_index(idx) {
    result = get_whois_record_by_index(idx, "netname");
    if (result != "") {
        return result;
    }

    result = get_whois_record_by_index(idx, "OrgName");
    if (result != "") {
        return result;
    }

    result = get_whois_record_by_index(idx, "owner");
    if (result != "") {
        return result;
    }

    result = get_whois_record_by_index(idx, "Organization");
    if (result != "") {
        return result;
    }

    return "";
}

function get_whois_country_by_index(idx) {
    result_country = get_whois_record_by_index(idx, "__COUNTRY__");
    if (result_country != "") {
        return result_country;
    }

    result_country = _get_whois_country_by_index(idx);
    if (result_country != "") {
        whois_append_field(idx, "__COUNTRY__", result_country);
    }

    return result_country;
}

function _get_whois_country_by_index(idx) {
    result = get_whois_record_by_index(idx, "Country");
    if (result != "") {
        result = toupper(result);
        if (result ~ /^EU/) {
            return "EU";
        }
        return result;
    }

    result = get_whois_record_by_index(idx, "country");
    if (result != "") {
        result = toupper(result);
        if (result ~ /^EU/) {
            return "EU";
        }
        return result;
    }

    phone = get_whois_phone_by_index(idx);
    if (phone != "") {
        if (phone ~ /[+]82/) {
            return "KR";
        }
    }

    organization = get_whois_owner_by_index(idx);
    if (organization != "") {
        if (organization ~ /24Shells/) {
            return "US";
        }
        if (organization ~ /Maxihost/) {
            return "BR";
        }
        if (organization ~ /SoftEther/) {
            return "JP";
        }
    }

    nameserver = get_whois_record_by_index(idx, "Nameserver");
    if (nameserver != "") {
        if (nameserver ~ /\.jp$/) {
            return "JP";
        }
    }

    return "";
}

function whois_append_field(idx, field, value) {
    n = whois_records[idx]["fields_length"];
    whois_records[idx]["fields_length"] = n + 1;
    whois_records[idx]["fields"][n + 1] = field;
    whois_records[idx]["values"][field] = value;
    whois_records_dirty = 1;
}

function whois_save_db() {
    if (whois_records_dirty == 0) {
        return "";
    }

    n = get_whois_length();
    for (i=1; i<=n; i++) {
        fields_length = whois_records[i]["fields_length"];
        out_line = "" fields_length;
        for (j=1; j<= fields_length; j++) {
            field = whois_records[i]["fields"][j];
            value = whois_records[i]["values"][field];
            out_line = (out_line "`" field "`" value);
        }
        if (i == 1) {
            print(out_line) > "whois.db";
        } else {
            print(out_line) >> "whois.db";
        }
    }

    close("whois.db");

    whois_reload_db();
}

function get_whois_iran_isp_by_index(idx) {
    result_isp = get_whois_record_by_index(idx, "__IRAN_ISP__");
    if (result_isp != "") {
        return result_isp;
    }

    result_isp = _get_whois_iran_isp_by_index(idx);
    if (result_isp != "") {
        whois_append_field(idx, "__IRAN_ISP__", result_isp);
    }

    return result_isp;
}

function _get_whois_iran_isp_by_index(idx) {
    organization = get_whois_owner_by_index(idx);
    if (organization != "") {
        if (organization ~ /^IR-MCI/ || organization ~ /^MCCI$/ || organization ~ /^MCI$/ || organization ~ /^MTCE$/) {
            return "MCI";
        }
        if (organization ~ /IRANCELL/) {
            return "Iran Cell";
        }
        if (organization ~ /TAMINTELECOM/ || toupper(organization) ~ /RIGHTEL/) {
            return "RighTel";
        }
        if (organization ~ /^(IR|NET)-ASK/ || toupper(organization) ~ /^ASK-ADSL/ || toupper(organization) ~ /^ASK$/ || organization ~ /^ANDISHGIL/ || organization ~ /^ASK-/) {
            return "Andishe Sabz Khazar";
        }
        if (organization ~ /^SHABDIZ/) {
            return "Shabdiz";
        }
        if (organization ~ /^PTS-DSL/ || organization ~ /^PTE$/ || organization ~ /^PJ-/ || organization ~ /^IR-PJCO/ || organization ~ /^HIGHSPEED-DSL/ || organization ~ /^PTE-/ || organization ~ /-PTE-/ || organization ~ /RoshangaranErtebatatRayaneh/ || organization ~ /^ADSL-USERS$/) {
            return "Pishgaman";
        }
        if (organization ~ /DATAK/ || toupper(organization) ~ /ROHAM/ || organization ~ /IR-GOSTAREH/) {
            return "Datak";
        }
        if (organization ~ /IR-FANAVA-/) {
            return "Fanava";
        }
        if (organization ~ /^DADEHGOSTAR-/ || organization ~ /^IR-RDGIR-/) {
            return "Hiweb";
        }
        if (organization ~ /IR-RSPN/ || toupper(organization) ~ /RESPINA/) {
            return "Respina";
        }
        if (organization ~ /^SHTL-/ || organization ~ /IR-RASANA/ || organization ~ /-FanVaAndishe$/ || organization ~ /IR-EBTEKARANDISHAN/) {
            return "Shatel";
        }
        if (organization ~ /^mana$/ || organization ~ /SEPANTA/) {
            return "Sepanta";
        }
        if (toupper(organization) ~ /^FANAPTELECOM/ || organization ~ /^SHABAKIEH/ || organization ~ /IR-JAVIDAN-/) {
            return "Fanap Telecom";
        }
        if (organization ~ /^IR-PARS/ || toupper(organization) ~ /PARSONLINE/ || organization ~ /Dynamic-pool-/) {
            return "ParsOnline";
        }
        if (tolower(organization) ~ /^khalijfarsonline$/ || tolower(organization) ~ /^khalij-fars-etela-resan$/ || tolower(organization) ~ /^khalije-fars-etela-resan$/ || tolower(organization) ~ /^khalij-fars-online$/ || tolower(organization) ~ /^khalij-fars-onlne$/) {
            return "Khalij Fars Online";
        }
        if (organization ~ /IR-SINET/) {
            return "Sinet";
        }
        if (organization ~ /^Asan-Khodro$/) {
            return "Asan Khodro";
        }
        if (organization ~ /^IR-SUMS$/) {
            return "Fars Province University of Medical Science and Health Care Services";
        }
        if (organization ~ /^IR-T-/ || organization ~ /^Tehran-Tejari$/ || organization ~ /^TCI/ || organization ~ /^IR-TC/ || organization ~ /PublicWifi/ || organization ~ /Internal/ || organization ~ /ARDEBIL/ || organization ~ /TELECOMMUNICATION/ || organization ~ /^DCI/ || organization ~ /^Area-/ || organization ~ /^EDUCATION/ || organization ~ /^IR-DCC/ || organization ~ /^tct-/ || organization ~ /tel$/ || organization ~ /^TELECOM/ || organization ~ /^TCE-/ || organization ~ /^GILTEL$/ ||
            organization ~ /^ORG-/ || organization ~ /-tct$/ || organization ~ /^TCS$/ || organization ~ /^ADSLSTATIC$/ || organization ~ /^ADSL[^-][^-]*$/ || organization ~ /^DLC[^-][^-]*/ || organization ~ /-adsl$/ || organization ~ /[^-][^-]*ICT$/ || organization ~ /IR-AFTAB-NETWORK-/ || organization ~ /^[a-zA-Z]DC$/ || organization ~ /^[a-zA-Z][a-zA-Z]*-TCI$/ || tolower(organization) ~ /-telecommunication$/ || organization ~ /^TCi-/ || organization ~ /^TCi-/ || organization ~ /^TCEWIFI$/ ||
            organization ~ /^TCM$/ || organization ~ /^tci[^-][^-]*$/ || organization ~ /-telecomunication$/) {
            return "Iran Telecommunication Company";
        }
        if (organization ~ /^IR-ASIATECH/ || organization ~ /^DEHLORAN$/ || organization ~ /^FARAMOJ-/ || organization ~ /^HEZARE$/) {
            return "Asia Tech";
        }
        if (organization ~ /^IR-SHIRAZHAMYAR/) {
            return "Hamyar Net";
        }
        if (organization ~ /ALBORZ-PARS/) {
            return "Alborz Pars";
        }
        if (organization ~ /IR-MABNA/) {
            return "Mabna Telecom";
        }
        if (organization ~ /IR-CYBER/) {
            return "Raya Sepehr";
        }
        if (toupper(organization) ~ /IR-BADRRAYAN/) {
            return "Badr Rayan";
        }
        if (organization ~ /MOBINNET/) {
            return "Mobin Net";
        }
        if (organization ~ /IR-ATRIN/ || organization ~ /ArtinCommunication/ || organization ~ /AtrinCommunication/ || organization ~ /RizPardazan-Danesh-Sarband/ || organization ~ /AtrtinNetwork/) {
            return "Artin Net";
        }
        if (organization ~ /IR-PEJVAK/) {
            return "Pejvak Net";
        }
        if (organization ~ /^MLS-/) {
            return "Boors";
        }
        if (organization ~ /AFRARASA/) {
            return "Afra Rasa";
        }
        if (organization ~ /IR-SUT/) {
            return "Shahroud University of Technology";
        }
        if (organization ~ /HojatiJavad/) {
            return "HojatiJavad";
        }
        if (organization ~ /MahanNet/) {
            return "Mahan Net";
        }
        if (organization ~ /IR-HESABGAR/ || organization ~ /IR-ARYA-/) {
            return "Tak Net";
        }
        if (organization ~ /Ayandeh-Net/) {
            return "Ertebatat Dourbord Fars";
        }
        if (organization ~ /IR-ABAN/) {
            return "Fanavaran Aban";
        }
        if (organization ~ /IR-PARVAZSYSTEM/) {
            return "Parvaz System";
        }
        if (toupper(organization) ~ /IR-AZARAKHSH/ || organization ~ /AryaOxin/) {
            return "Arya Oxin";
        }
        if (organization ~ /Avagostar/) {
            return "Ava Gostar";
        }
        if (organization ~ /IR-FARABORD/ || organization ~ /LTE-BSNS-/) {
            return "Zitel";
        }
        if (organization ~ /Shoushtar_Medical_School/) {
            return "Shoushtar Medical School";
        }
        if (organization ~ /IR-KAVOSHGAR/) {
            return "Kavoshgar Novin";
        }
        if (organization ~ /^Dedicated-BroadBand$/) {
            return "Kharg";
        }
        if (organization ~ /^DPA$/) {
            return "Data Pardaz";
        }
        if (organization ~ /IR-DAYAN/) {
            return "Dayan Shabake Gostar";
        }
        if (organization ~ /IR-REFATEC/ || organization ~ /IR-CMA/) {
            return "Refah Tec";
        }
        if (organization ~ /ASRETELECOM/) {
            return "Asre Telecom";
        }
        if (organization ~ /Are-Rayane/) {
            return "Asr Telecom";
        }
        if (organization ~ /INFRA/) {
            return "INFRA";
        }
        if (organization ~ /^NGS/ || organization ~ /^IR-PARVARESH/ || organization ~ /SABANET/) {
            return "Saba Net";
        } 
        if (organization ~ /^SBUK$/) {
            return "Shahid Bahonar University of Kerman";
        }
        if (organization ~ /^KUMSNET$/) {
            return "Kerman University of Medical Sciences";
        }
        if (organization ~ /^Didi$/) {
            return "Dideh Ban Net";
        }
        if (organization ~ /^IR_DORNA/ || organization ~ /^IR-DORNA/) {
            return "Uz Net";
        }
        if (organization ~ /^ITMCI$/) {
            return "International Travel Medicine Center";
        }
        if (organization ~ /Shabakeyeh-Sepehr/) {
            return "Ertebat Gostar";
        }
        if (organization ~ /NIOCI/) {
            return "National Iranian Oil Company";
        }
        if (toupper(organization) ~ /^MODARES$/) {
            return "Tarbiat Modares University";
        }
        if (organization ~ /HAMARASYSTEM/ || organization ~ /^LASER$/) {
            return "Hamara System";
        }
        if (organization ~ /^OMIDAN-/) {
            return "Omidan";
        }
        if (organization ~ /SAPCO/) {
            return "Iran Khodro";
        }
        if (organization ~ /JN-NET/) {
            return "Mysha Net";
        }
        if (organization ~ /^TUMS$/) {
            return "Tehran University of Medical Sciences";
        }
        if (organization ~ /HAJ-OGHAF/) {
            return "Haj-Oghaf";
        }
        if (organization ~ /PETRO-GAZ/ || organization ~ /AFRANET/ || organization ~ /^Ima-Hamrah$/ || organization ~ /^POUYESH-PARDAZ$/) {
            return "Afra Net";
        }
        if (organization ~ /^SCC$/) {
            return "Soufian Cement Co";
        }
        if (organization ~ /AZADUNIVERSITY/ || organization ~ /^AZ[a-zA-Z][a-zA-Z]$/ || organization ~ /^LIAU$/ || organization ~ /^UNAZAD[^-]*$/) {
            return "Azad University";
        }
        if (organization ~ /PANAONE/) {
            return "Panaone Net";
        }
        if (organization ~ /Parsis-Net/) {
            return "Parsis Net";
        }
        if (organization ~ /RAHANET/) {
            return "Raha Net";
        }
        if (organization ~ /GOLNET/) {
            return "Gol Net";
        }
        if (organization ~ /HAIERNET/) {
            return "Arya Gostar Spadana";
        }
        if (organization ~ /CIS-IT/) {
            return "CIS-IT";
        }
        if (toupper(organization) ~ /SEFROYEK/) {
            return "0-1.ir";
        }
        if (organization ~ /^AISDP$/) {
            return "Aseman Faraz Sepahan";
        }
        if (organization ~ /BANKMAS/) {
            return "Bank Maskan";
        }
        if (organization ~ /^SS-SYSTEC/) {
            return "Systech";
        }
        if (organization ~ /Bahar_Samaneh/ || organization ~ /^ZENTEX$/ || organization ~ /^BS_BROADBAND/) {
            return "Bahar Net";
        }
        if (organization ~ /IR-ASREDANESH/) {
            return "Asr Danesh Afzar";
        }
        if (organization ~ /IR-SHAHRAD/) {
            return "Shahrad";
        }
        if (toupper(organization) ~ /SUNINTERNET/) {
            return "Sun Internet";
        }
        if (organization ~ /Farzanegan-/) {
            return "Wenex";
        }
        if (organization ~ /IR-PAPER/) {
            return "Tadarok Kerman Paper Company";
        }
        if (organization ~ /PARTPAYAM/ || organization ~ /PARTPATAM/) {
            return "Part Payam Shahin Shahr";
        }
        if (organization ~ /HOSTIRAN-NET/) {
            return "Host Iran";
        }
        if (organization ~ /PETIAK/) {
            return "Petiak";
        }
        if (organization ~ /^WiMAX$/) {
            return "WiMAX";
        }
        if (organization ~ /^MXNT-/) {
            return "Max Net";
        }
        if (organization ~ /^GOVNT$/) {
            return "Guilan Governemt Building in Rasht";
        }
        if (organization ~ /^Aryasat$/ || organization ~ /ILAM-NEWNET/) {
            return "Aryasat";
        }
        if (organization ~ /^hichestan$/) {
            return "Hichestan";
        }
        if (organization ~ /^Abadan_University_of_Medical_Sciences$/) {
            return "Abadan University of Medical Sciences";
        }
        if (organization ~ /HOOSHANNET/) {
            return "Hooshan Net";
        }
        if (organization ~ /APAD/) {
            return "Urmia University";
        }
        if (organization ~ /^Cybertech$/) {
            return "Cybertech";
        }
        if (organization ~ /^AIDINSYSTEM/) {
            return "Aidin System Boushehr";
        }
        if (organization ~ /NOAVJOLFA/) {
            return "Jolfa Net";
        }
        if (organization ~ /^IR-ESP$/ || organization ~ /^Hirad-ISP$/) {
            return "Ertebatar Sabet Parsian";
        }
        if (organization ~ /Boomerang-Rayaneh/) {
            return "Boomerang Rayaneh";
        }
        if (organization ~ /YasOnline/) {
            return "Yas Online";
        }
        if (organization ~ /^TRLCO$/ || organization ~ /IR-AVA-ARVAND-/) {
            return "Webotel";
        }
        if (tolower(organization) ~ /asre-ertebat/) {
            return "Asre Ertebat";
        }
        if (organization ~ /IR-MOEIN-DADOSETAD/) {
            return "Moin Dadosetad Golestan";
        }
        if (organization ~ /IR-BITA/) {
            return "Bita Net";
        }
        if (organization ~ /BahoonarUniversityKerman/) {
            return "Bahonar University Kerman";
        }
        if (tolower(organization) ~ /faratelecom/) {
            return "Fara Telecom";
        }
        if (organization ~ /IR-POOYA/) {
            return "Pooya Part o Gheshm";
        }
        if (tolower(organization) ~ /ir-satiareyertebat/) {
            return "Satia ISP";
        }
        if (organization ~ /IR-NOAVARAN/) {
            return "Noavaran System Sarv";
        }
        if (organization ~ /IR-SAMSYSTEM/) {
            return "Zaman ISP";
        }
        if (organization ~ /^Shabakieh[^-][^-]*$/) {
            return "Shabakieh";
        }
        if (organization ~ /IR-MANA/) {
            return "Mana Net";
        }
        if (organization ~ /Sabz-Dsl/) {
            return "sabzonline";
        }
        if (organization ~ /IR-CITC/ || organization ~ /^UTNET$/) {
            return "University of Tehran";
        }
        if (organization ~ /ARAXNET/) {
            return "Araax";
        }
        if (organization ~ /IR-PARDAZESHNET-/) {
            return "Pardazesh Net";
        }
        if (organization ~ /^Fixed-Broadband-Subscriber$/) {
            return "Dotin";
        }
        if (organization ~ /^SHABAKEGOSTARAN$/) {
            return "Shabake Gostaran Zanjan";
        }
        if (organization ~ /^Machine-Sazi-Arak/) {
            return "Mashin Sazi Arak";
        }
        if (organization ~ /ARKBUS-AWB/) {
            return "ARKBUS ISP (Arak)";
        }
        if (organization ~ /^[a-zA-Z][a-zA-Z]EC$/) {
            return "Electric Company";
        }
        if (organization ~ /^DABAINCO$/) {
            return "Dadash Baradar Co";
        }
        if (organization ~ /fayez-rayaneh-/) {
            return "Fayez Online";
        }
        if (organization ~ /IR-SSPP-/) {
            return "Bank Parsian";
        }
        if (organization ~ /^NIDC$/) {
            return "National Iranian Drilling Company";
        }
        if (organization ~ /UK-PRIVAX-/) {
            return "AVAST Software";
        }
        if (organization ~ /^IRIB-/) {
            return "IRIB";
        }
        if (organization ~ /MihanWebHost/) {
            return "Mihan Web Host";
        }
        if (organization ~ /-seanet-/ || organization ~ /-seanet$/) {
            return "Sea Net";
        }
        if (organization ~ /ZNU-Server-Farm/) {
            return "Zanjan University Server Farm";
        }
        if (organization ~ /SariSystemBandarabasCompany/) {
            return "Sari System Jonub";
        }
        if (organization ~ /ZabolUniversityofMedicalSciences/) {
            return "Zabol University of Medical Sciences";
        }
        if (organization ~ /FARAGOSTAR/) {
            return "Faragostar Shargh";
        }
        if (organization ~ /^MEHRAVA$/) {
            return "Mehr Net";
        }
        if (organization ~ /SoratGostarErtebatatParsian/) {
            return "Sorat Gostar Ertebatat";
        }
        if (organization ~ /IR-KOSARAN-/) {
            return "Kosar Ghadir Kariman Agro-Industrial Complex";
        }
    }

    return "";
}

function _get_whois_record_index_by_ip(ip) {
    for (_get_whois_record_index_by_ip_counter=1; _get_whois_record_index_by_ip_counter<=ignore_list_length; _get_whois_record_index_by_ip_counter++) {
        if (ignore_list[_get_whois_record_index_by_ip_counter] == ip) {
            return 0;
        }
    }

    target_ip = fix_ip(ip);

    n = get_whois_length();
    for (_get_whois_record_index_by_ip_counter=1; _get_whois_record_index_by_ip_counter<=n; _get_whois_record_index_by_ip_counter++) {
        start_ip = get_whois_record_ip_start_by_index(_get_whois_record_index_by_ip_counter);
        end_ip = get_whois_record_ip_end_by_index(_get_whois_record_index_by_ip_counter);

        if (target_ip >= start_ip && target_ip <= end_ip) {
            return _get_whois_record_index_by_ip_counter;
        }
    }

    return 0;
}

function get_whois_record_index_by_ip(ip) {
    target_ip = fix_ip(ip);

    bs_start = 1;
    bs_end = get_whois_length();

    while (bs_start < bs_end) {
        mid = int((bs_start + bs_end) / 2);
        if (target_ip < whois_records_start_ips[mid]) {
            bs_start = mid + 1;
        } else {
            bs_end = mid;
        }
    }

    if (bs_start == bs_end) {
        start_ip = get_whois_record_ip_start_by_index(bs_start);
        end_ip = get_whois_record_ip_end_by_index(bs_start);

        if (target_ip >= start_ip && target_ip <= end_ip) {
            return bs_start;
        }
    }

    result = _get_whois_record_index_by_ip(ip);
    if (result == 0) {
        fetch_whois(ip);

        result = _get_whois_record_index_by_ip(ip);
        if (result == 0) {
            return 0;
        }
    }

    return result;
}

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

function sort_counter_key_decreasing(type, key) {
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

    for (key_counter=1; key_counter<=stats_counter["type"][type]["count"]; key_counter++) {
        key = stats_counter["type"][type]["keys"][key_counter];

        sort_counter_key_decreasing(type, key);

        stats_counter["type"][type]["sorted_count"] = stats_counter["type"][type]["sorted_count"] + 1;
        stats_counter["type"][type]["sorted_keys"][stats_counter["type"][type]["sorted_count"]] = key;

        for (key_sort_counter=stats_counter["type"][type]["sorted_count"]; key_sort_counter>=2; key_sort_counter--) {
            next_key_sort_counter = key_sort_counter - 1;

            key_sort = stats_counter["type"][type]["sorted_keys"][key_sort_counter];
            next_key_sort = stats_counter["type"][type]["sorted_keys"][next_key_sort_counter];

            key_sort_value = stats_counter["type"][type]["key"][key_sort]["field"][field];
            next_key_sort_value = stats_counter["type"][type]["key"][next_key_sort]["field"][field];

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
    if (fn == "sum" || fn == "count") {
        _ensure_counter(type, "_", fn);
        return stats_counter["type"][type]["key"]["_"]["field"][fn];
    }
    print "ERROR: Undefined aggregate function: [" fn "]";
    return "";
}

function sort_counter_decreasing_using(fn) {
    stats_counter["sorted_count"] = 0;

    for (type_counter=1; type_counter<=stats_counter["count"]; type_counter++) {
        type = stats_counter["types"][type_counter];

        sort_counter_type_decreasing_on_field(type, fn);

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

                    if (field != "sum" || stats_counter["display"]["show_sum"] != "off") {
                        value = stats_counter["type"][type]["key"][key]["field"][field];

                        if (field != "count" && stats_counter["display"]["type"] == "percent") {
                            value = (value / stats_counter["type"][type]["key"][key]["field"]["sum"]) * 100;
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

/(PUT|POST)/ {
    if ((NR % 5000) == 0) {
        set_counter_display_option("type", "percent");
        set_counter_display_option("show_sum", "off");

        #set_counter_display_option("type", "none");
        #set_counter_display_option("show_sum", "on");

        sort_counter_decreasing();
        report_counter_txt();

        print ("***************************************");
    }

    is_error = match($0, /\[error\]/);
    if (is_error == 0) {
        ip = $3;
        idx = match(ip, /[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*/)
        if (idx == 0) {
            print "ERROR: could not find IP address for [" $0 "] at [" NR "]";
        } else {
            idx = match($0, /HTTP\/1\.1" /)
            if (idx == 0) {
                print "ERROR: could not locate HTTP directive for [" $0 "] at [" NR "]";
            } else {
                line = substr($0, idx + 10);

                idx = match(line, /^[0-9][0-9][0-9] /) 
                if (idx == 0) {
                    print "ERROR: could not locate status code for [" $0 "] at [" NR "]";
                } else {
                    status = int(substr(line, 1, 3));
                    method = "PUT";

                    if (match($0, /"POST \//) != 0) {
                        method = "POST";
                    }

                    error_type = "UNKNOWN";
                    if (status >= 200 && status < 300) {
                        error_type = "OK";
                    } else if (status >= 300 && status < 400) {
                        error_type = "REDIRECT";
                    } else if (status >= 400 && status < 490) {
                        error_type = "CLIENT";
                    } else if (status >= 490 && status < 500) {
                        error_type = "CLIENT_CLOSED";
                    } else if (status >= 500 && status < 600) {
                        error_type = "SERVER";
                    }

                    idx = get_whois_record_index_by_ip(ip);
                    if (idx == 0) {
                        print "ERROR: could not locate whois information for [" $0 "] at [" NR "]";
                    } else {
                        increment_counter("World", "World", error_type, 1);

                        country = get_whois_country_by_index(idx);
                        if (country == "") {
                            country = "(UNKNOWN)";
                            region = "(UNKNOWN)";
                        } else if (country == "IR") {
                            region = "IR";
                        } else {
                            region = "Outside-IR";
                        }

                        increment_counter("Country", country, error_type, 1);
                        increment_counter("Region", region, error_type, 1);

                        if (country == "IR") {
                            isp = get_whois_iran_isp_by_index(idx);
                            if (isp == "") {
                                isp = "(UNKNOWN)";
                            }

                            increment_counter("Iran ISP", isp, error_type, 1);
                        }

                        ########
                    }
                }
            }
        }
    }
}

/^[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*$/ {
    if (NR % 100 == 0) {
        whois_save_db();
        
        print "";
        print ">> [" NR "]";
        print "";

        for (i=1; i<=country_list_length; i++) {
            print "C=[" country_list[i] "] = " country_count[country_list[i]];
        }

        print "";
        print "-----------------";
        print "";

        for (i=1; i<=isp_list_length; i++) {
            print "ISP[" isp_list[i] "] = " isp_count[isp_list[i]];
        }

        print "";
        print "";
    }
    idx = get_whois_record_index_by_ip($0);
    if (idx == 0) {
        print "ERROR: could not fetch [" $0 "] at [" NR "]";
    } else {
        country = get_whois_country_by_index(idx);
        if (country == "") {
            print "ERROR: could not find country for [" $0 "] at [" NR "]";
            country = "[UNKNOWN]";
        } 

        if (country == "IR") {
            print "IR_IP=" $0;
 
            isp = get_whois_iran_isp_by_index(idx);
            if (isp == "") {
                organization = get_whois_owner_by_index(idx);
                print "ERROR: could not find ISP for [" $0 "] owner=[" organization "] at [" NR "]"; 
                isp = "[UNKNOWN]";
            } 

            if (isp_count[isp] == "") {
                if (isp_list_length == "") {
                    isp_list_length = 0;
                }
 
                isp_list_length = isp_list_length + 1;
                isp_list[isp_list_length] = isp;
                isp_count[isp] = 0;
            }
 
            isp_count[isp] = isp_count[isp] + 1;
        }
 
        if (country_count[country] == "") {
           if (country_list_length == "") {
               country_list_length = 0;
           }
 
           country_list_length = country_list_length + 1;
           country_list[country_list_length] = country;
           country_count[country] = 0;
        }
 
        country_count[country] = country_count[country] + 1;
    }
}

END {
    set_counter_display_option("type", "percent");
    set_counter_display_option("show_sum", "off");
    sort_counter_decreasing();
    report_counter_txt();

    whois_save_db();
}
