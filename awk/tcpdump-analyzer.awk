BEGIN {
    session_duration_length = 0;
    session_until_closure_duration_length = 0;
    retransmission_delay_length = 0;
    all_sessions_length = 0;
}

/Flags/ {
    ERR_TCP_SYN_RETRANSMISSION = "TCP_SYN_RETRANSMISSION";
    ERR_TCP_SYN_SEQ_EXPECTED = "TCP_SYN_SEQ_EXPECTED";
    ERR_TCP_SYNACK_SEQ_EXPECTED = "TCP_SYNACK_SEQ_EXPECTED";
    ERR_TCP_UNEXPECTED_SYN = "TCP_UNEXPECTED_SYN";
    ERR_TCP_UNEXPECTED_SYNACK = "TCP_UNEXPECTED_SYNACK";
    ERR_TCP_UNEXPECTED_SYNACK_SEQUENCE = "TCP_UNEXPECTED_SYNACK_SEQUENCE";
    ERR_TCP_UNEXPECTED_HANDSHAKE_CLIENT_ACK = "TCP_UNEXPECTED_HANDSHAKE_CLIENT_ACK";
    ERR_TCP_UNEXPECTED_HANDSHAKE_CLIENT_ACK_SEQUENCE = "TCP_UNEXPECTED_HANDSHAKE_CLIENT_ACK_SEQUENCE";
    ERR_TCP_UNEXPECTED_HANDSHAKE_FLAGS = "TCP_UNEXPECTED_HANDSHAKE_FLAGS";
    ERR_TCP_UNEXPECTED_TRANSMISSION_CLIENT_TO_SERVER_SEQUENCE = "TCP_UNEXPECTED_TRANSMISSION_CLIENT_TO_SERVER_SEQUENCE";
    ERR_TCP_UNEXPECTED_TRANSMISSION_SERVER_TO_CLIENT_SEQUENCE = "TCP_UNEXPECTED_TRANSMISSION_SERVER_TO_CLIENT_SEQUENCE";
    ERR_TCP_UNEXPECTED_TRANSMISSION_CLIENT_TO_SERVER_ACK = "TCP_UNEXPECTED_TRANSMISSION_CLIENT_TO_SERVER_ACK";
    ERR_TCP_UNEXPECTED_TRANSMISSION_SERVER_TO_CLIENT_ACK = "TCP_UNEXPECTED_TRANSMISSION_SERVER_TO_CLIENT_ACK";
    ERR_TCP_TRANSMISSION_CLIENT_TO_SERVER_NOT_ENOUGH_ACKNOWLEDGE = "TCP_TRANSMISSION_CLIENT_TO_SERVER_NOT_ENOUGH_ACKNOWLEDGE";
    ERR_TCP_TRANSMISSION_SERVER_TO_CLIENT_NOT_ENOUGH_ACKNOWLEDGE = "TCP_TRANSMISSION_SERVER_TO_CLIENT_NOT_ENOUGH_ACKNOWLEDGE";
    ERR_TCP_LATENCY = "TCP_LATENCY";
    ERR_TCP_BUFFER_CLIENT_TO_SERVER_LATENCY = "TCP_BUFFER_CLIENT_TO_SERVER_LATENCY";
    ERR_TCP_BUFFER_SERVER_TO_CLIENT_LATENCY = "TCP_BUFFER_SERVER_TO_CLIENT_LATENCY";
    ERR_TCP_SYN_RESET = "TCP_SYN_RESET";
    ERR_TCP_CLIENT_TO_SERVER_RETRANSMISSION = "TCP_CLIENT_TO_SERVER_RETRANSMISSION";
    ERR_TCP_SERVER_TO_CLIENT_RETRANSMISSION = "TCP_SERVER_TO_CLIENT_RETRANSMISSION";
    ERR_TCP_UNEXPECTED_FIN_CLIENT_TO_SERVER_SEQUENCE = "TCP_UNEXPECTED_FIN_CLIENT_TO_SERVER_SEQUENCE";
    ERR_TCP_UNEXPECTED_SECOND_FIN_CLIENT_TO_SERVER_SEQUENCE = "TCP_UNEXPECTED_SECOND_FIN_CLIENT_TO_SERVER_SEQUENCE";
    ERR_TCP_UNEXPECTED_FIN_SERVER_TO_CLIENT_SEQUENCE = "TCP_UNEXPECTED_FIN_SERVER_TO_CLIENT_SEQUENCE";
    ERR_TCP_UNEXPECTED_SECOND_FIN_SERVER_TO_CLIENT_SEQUENCE = "TCP_UNEXPECTED_SECOND_FIN_SERVER_TO_CLIENT_SEQUENCE";
    ERR_TCP_UNEXPECTED_FIN_CLIENT_TO_SERVER_ACK = "TCP_UNEXPECTED_FIN_CLIENT_TO_SERVER_ACK";
    ERR_TCP_UNEXPECTED_SECOND_FIN_CLIENT_TO_SERVER_ACK = "TCP_UNEXPECTED_SECOND_FIN_CLIENT_TO_SERVER_ACK";
    ERR_TCP_UNEXPECTED_FIN_SERVER_TO_CLIENT_ACK = "TCP_UNEXPECTED_FIN_SERVER_TO_CLIENT_ACK";
    ERR_TCP_UNEXPECTED_SECOND_FIN_SERVER_TO_CLIENT_ACK = "TCP_UNEXPECTED_SECOND_FIN_SERVER_TO_CLIENT_ACK";
    ERR_TCP_FIN_CLIENT_TO_SERVER_NOT_ENOUGH_ACKNOWLEDGE = "TCP_FIN_CLIENT_TO_SERVER_NOT_ENOUGH_ACKNOWLEDGE";
    ERR_TCP_SECOND_FIN_CLIENT_TO_SERVER_NOT_ENOUGH_ACKNOWLEDGE = "TCP_SECOND_FIN_CLIENT_TO_SERVER_NOT_ENOUGH_ACKNOWLEDGE";
    ERR_TCP_FIN_SERVER_TO_CLIENT_NOT_ENOUGH_ACKNOWLEDGE = "TCP_FIN_SERVER_TO_CLIENT_NOT_ENOUGH_ACKNOWLEDGE";
    ERR_TCP_SECOND_FIN_SERVER_TO_CLIENT_NOT_ENOUGH_ACKNOWLEDGE = "TCP_SECOND_FIN_SERVER_TO_CLIENT_NOT_ENOUGH_ACKNOWLEDGE";
    ERR_TCP_INVALID_FLAGS = "TCP_INVALID_FLAGS";
    ERR_TCP_FIN_INVALID_FLAGS = "TCP_FIN_INVALID_FLAGS";
    ERR_TCP_SECOND_FIN_INVALID_FLAGS = "TCP_SECOND_FIN_INVALID_FLAGS";
    ERR_TCP_FIN_RETRANSMISSION = "TCP_FIN_RETRANSMISSION";
    ERR_TCP_SECOND_FIN_RETRANSMISSION = "TCP_SECOND_FIN_RETRANSMISSION";
    ERR_TCP_FIN_RECEIVER_UNEXPECTED_ACK = "TCP_FIN_RECEIVER_UNEXPECTED_ACK";
    ERR_TCP_SECOND_FIN_RECEIVER_UNEXPECTED_ACK = "TCP_SECOND_FIN_RECEIVER_UNEXPECTED_ACK";
    ERR_TCP_FIN_RECEIVER_PENDING_ACKNOWLEDGE = "TCP_FIN_RECEIVER_PENDING_ACKNOWLEDGE";
    ERR_TCP_SECOND_FIN_RECEIVER_PENDING_ACKNOWLEDGE = "TCP_SECOND_FIN_RECEIVER_PENDING_ACKNOWLEDGE";
    ERR_TCP_CLIENT_TO_SERVER_REQUESTED_RETRANSMISSION = "TCP_CLIENT_TO_SERVER_REQUESTED_RETRANSMISSION";
    ERR_TCP_SERVER_TO_CLIENT_REQUESTED_RETRANSMISSION = "TCP_SERVER_TO_CLIENT_REQUESTED_RETRANSMISSION";
    ERR_TCP_TRANSMISSION_CLIENT_TO_SERVER_DATALOSS = "TCP_TRANSMISSION_CLIENT_TO_SERVER_DATALOSS";
    ERR_TCP_TRANSMISSION_SERVER_TO_CLIENT_DATALOSS = "TCP_TRANSMISSION_SERVER_TO_CLIENT_DATALOSS";
    ERR_TCP_FINACK_INVALID_FLAGS = "TCP_FINACK_INVALID_FLAGS";
    ERR_TCP_CLIENT_TO_SERVER_RETRANSMISSION_DELAY = "TCP_CLIENT_TO_SERVER_RETRANSMISSION_DELAY";
    ERR_TCP_SERVER_TO_CLIENT_RETRANSMISSION_DELAY = "TCP_SERVER_TO_CLIENT_RETRANSMISSION_DELAY";
    ERR_TCP_PACKET_ON_CLOSED_CONNECTION = "TCP_PACKET_ON_CLOSED_CONNECTION";

    MAX_ALLOWED_LATENCY = 0.3;

    error = "";
    warn = "";

    sender=$3;
    receiver=$5;
    flags=$7;

    sub(/:/,"",receiver);
    sub(/\[/,"",flags);
    sub(/],/,"",flags);

    split($1,time_parts,":");
    t=time_parts[1]*3600 + time_parts[2]*60 + time_parts[3]*1;

    if ($8 == "seq") {
        temp=$9;
        sub(/,/,"",temp);

        if (temp ~ /:/) {
            sequence_type="range";
            split(temp,sequence_range,":");
        } else {
            sequence_type="absolute";
            sequence=temp;
        }
    } else {
        sequence_type="";
    }

    if ($8 == "ack") {
        ack=$9;
        sub(/,/,"",ack);
        ack=ack*1;
    } else if ($10 == "ack") {
        ack=$11;
        sub(/,/,"",ack);
        ack=ack*1;
    } else {
        ack="";
    }

    if (flags == "S") {
        session=sender;
        mode="client-to-server";
        state="handshake-syn-sent"

        if (session_state[session] == "handshake-syn-sent") {
            if ((t-start_t[session]) > 60) {
                start_t[session]=t;
                session_retransmission_delay[session] = 0;
            } else {
                error = (error ERR_TCP_SYN_RETRANSMISSION "(delay " (t-start_t[session]) " s)" ",");
                session_retransmission_delay[session] = session_retransmission_delay[session] + (t-start_t[session]);
            }
        } else {
            start_t[session]=t;
            session_retransmission_delay[session] = 0;
            all_sessions_length = all_sessions_length + 1;
            all_sessions[all_sessions_length] = session;
        }

        session_state[session]="handshake-syn-sent"
    } else {
        if (start_t[sender] != "") {
            session=sender;
            mode="client-to-server";
            state=session_state[session]
        } else if (start_t[receiver] != "") {
            session=receiver;
            mode="server-to-client";
            state=session_state[session]
        } else {
            mode="invalid"
        }

        if (mode != "invalid") {
            t=t-start_t[session];
        }
    }

    if (mode != "invalid") { 
        if (state == "handshake-syn-sent") {
            if (flags != "S") {
                error = (error ERR_TCP_UNEXPECTED_HANDSHAKE_FLAGS "(" flags ")" ",");
            }
            else if (mode == "client-to-server") {
                if (sequence_type != "absolute") {
                    error = (error ERR_TCP_SYN_SEQ_EXPECTED ",");
                } else {
                    expected_ack_from_server[session]=sequence + 1;
                    session_state[session]="handshake-syn-ack-expected";
                    syn_sent[session]=t
                }
            } else {
                error = (error ERR_TCP_UNEXPECTED_SYN ",");
            }
        } else if (state == "handshake-syn-ack-expected") {
            if (mode == "server-to-client") {
                if (flags != "S." && flags != "R.") {
                    error = (error ERR_TCP_UNEXPECTED_HANDSHAKE_FLAGS "(" flags ")" ",");
                } else {
                    if (flags == "R.") {
                        error = (error ERR_TCP_SYN_RESET ",");
                    }

                    if (ack != expected_ack_from_server[session]) {
                        error = (error ERR_TCP_UNEXPECTED_SYNACK_SEQUENCE ",");
                    } else {
                        if ((t-syn_sent[session]) > MAX_ALLOWED_LATENCY) {
                            error = (error ERR_TCP_LATENCY "(" (t-syn_sent[session]) " s)" ",");
                        }

                        if (sequence_type != "absolute") {
                            error = (error ERR_TCP_SYNACK_SEQ_EXPECTED ",");
                        } else {
                            expected_ack_from_client[session]=sequence + 1;

                            if (flags == "S.") {
                                session_state[session]="handshake-client-ack-expected";
                                ack_received[session]=t;
                            }
                        }
                    }
                }
            } else {
                error = (error ERR_TCP_UNEXPECTED_SYNACK ",");
            }
        } else if (state == "handshake-client-ack-expected") {
            if (mode == "client-to-server") {
                if (flags != ".") {
                    error = (error ERR_TCP_UNEXPECTED_HANDSHAKE_FLAGS "(" flags ")" ",");
                } else {
                    if (ack != expected_ack_from_client[session] && ack != 1) {
                        error = (error ERR_TCP_UNEXPECTED_HANDSHAKE_CLIENT_ACK_SEQUENCE ",");
                    } else {
                        if ((t-ack_received[session]) > MAX_ALLOWED_LATENCY) {
                            error = (error ERR_TCP_LATENCY "(" (t-ack_received[session]) " s)" ",");
                        }

                        expected_ack_from_client[session] = ack;
                        session_state[session] = "established";
                        client_transmitted[session] = 1;
                        server_transmitted[session] = 1;
                    }
                }
            } else {
                error = (error ERR_TCP_UNEXPECTED_HANDSHAKE_CLIENT_ACK ",");
            }
        } else if (state == "established") {
            if (flags == "P." || flags == ".") {
                if (mode == "client-to-server") {
                    if (client_buffer[session] != "") {
                        if (flags == "P.") {
                            if ((t-client_buffer[session]) > MAX_ALLOWED_LATENCY) {
                                warn = (warn ERR_TCP_BUFFER_CLIENT_TO_SERVER_LATENCY "(" (t-client_buffer[session]) " s)" ",");
                            }
                            client_buffer[session] = t;
                        }
                    } else if (flags == ".") {
                        client_buffer[session] = t;
                    }

                    if (sequence_type == "range") {
                        nok = 0;
                        if (sequence_range[1] > client_transmitted[session]) {
                            error = (error ERR_TCP_TRANSMISSION_CLIENT_TO_SERVER_DATALOSS "(missing " (sequence_range[1] - client_transmitted[session]) " bytes)"  ",");
                            for (i=sequence_range[1]; i <= sequence_range[2]; i++) {
                                client_jitter_transmitted[session][i] = 1;
                            }
                            client_jitter_t[session][sequence_range[2]] = t;
                            nok = 1;
                        } else if (sequence_range[1] < client_transmitted[session]) {
                            error = (error ERR_TCP_CLIENT_TO_SERVER_RETRANSMISSION "(" (t-client_transmitted_t[session]) " s)" ",");
                            nok = 1;
                        }

                        if (sequence_range[2] < sequence_range[1]) {
                            error = (error ERR_TCP_UNEXPECTED_TRANSMISSION_CLIENT_TO_SERVER_SEQUENCE ",");
                            nok = 1;
                        }

                        if (nok == 0) {
                            client_transmitted[session] = sequence_range[2];
                        }

                        client_transmitted_t[session] = t;
                        client_transmitted_part_t[session][sequence_range[2]] = t;
                    } else if (sequence_type != "") {
                        error = (error ERR_TCP_UNEXPECTED_TRANSMISSION_CLIENT_TO_SERVER_SEQUENCE ",");
                    }

                    if (ack == "") {
                        error = (error ERR_TCP_UNEXPECTED_TRANSMISSION_CLIENT_TO_SERVER_ACK ",");
                    } else {
                        jitter_t = "";
                        for (i = server_transmitted[session]+1; server_jitter_transmitted[session][i] == 1; i++) {
                            server_transmitted[session]++;
                            if (server_jitter_t[session][i] != "" && (jitter_t == "" || jitter_t < server_jitter_t[session][i])) {
                                jitter_t = server_jitter_t[session][i];
                            }
                        }

                        if (jitter_t != "") {
                            error = (error ERR_TCP_SERVER_TO_CLIENT_RETRANSMISSION_DELAY "(" (t-jitter_t) " s)" ",");
                            session_retransmission_delay[session] = session_retransmission_delay[session] + (t-jitter_t);
                        }

                        if (ack > server_transmitted[session]) {
                            error = (error ERR_TCP_UNEXPECTED_TRANSMISSION_CLIENT_TO_SERVER_ACK "(expected=" server_transmitted[session] " ack=" ack ")" ",");
                        }

                        if (ack < server_transmitted[session]) {
                            # error = (error ERR_TCP_TRANSMISSION_CLIENT_TO_SERVER_NOT_ENOUGH_ACKNOWLEDGE ",");
                            # no problem, possibly due to big window size
                        }

                        if (ack == server_transmitted[session]) {
                            for (i = ack + 1; server_jitter_transmitted[session][i] == 1; i++) {
                                server_transmitted[session]++;
                            }
                        }

                        if (last_client_ack[session][ack] != 1 && (t - server_transmitted_t[session]) > MAX_ALLOWED_LATENCY) {
                            error = (error ERR_TCP_LATENCY "(" (t-server_transmitted_t[session]) " s)" ",");
                        }

                        if ((last_client_ack[session][ack] != 1) && (server_transmitted_part_t[session][ack] != "") && ((t-server_transmitted_part_t[session][ack])>MAX_ALLOWED_LATENCY)) {
                            error = (error ERR_TCP_LATENCY "(" (t-server_transmitted_part_t[session][ack]) " s)" ",");
                        }

                        if (last_client_ack[session][ack] == 1 && sequence_type == "") {
                            error = (error ERR_TCP_CLIENT_TO_SERVER_REQUESTED_RETRANSMISSION "(delay " (t-server_transmitted_part_t[session][ack]) " s)"  ",");
                            session_retransmission_delay[session] = session_retransmission_delay[session] + (t-server_transmitted_part_t[session][ack]);
                        }
                        last_client_ack[session][ack] = 1;

                        expected_ack_from_server[session] = ack;
                    }
                } else {
                    if (server_buffer[session] != "") {
                        if (flags == "P.") {
                            if ((t-server_buffer[session]) > MAX_ALLOWED_LATENCY) {
                                warn = (warn ERR_TCP_BUFFER_SERVER_TO_CLIENT_LATENCY "(" (t-server_buffer[session]) " s)" ",");
                            }
                            server_buffer[session] = t;
                        }
                    } else if (flags == ".") {
                        server_buffer[session] = t;
                    }

                    if (sequence_type == "range") {
                        nok = 0;
                        if (sequence_range[1] > server_transmitted[session]) {
                            error = (error ERR_TCP_TRANSMISSION_SERVER_TO_CLIENT_DATALOSS "(missing " (sequence_range[1] - client_transmitted[session]) " bytes)"  ",");
                            for (i=sequence_range[1]; i <= sequence_range[2]; i++) {
                                server_jitter_transmitted[session][i] = 1;
                            }
                            server_jitter_t[session][sequence_range[2]] = t;
                            nok = 1;
                        } else if (sequence_range[1] < server_transmitted[session]) {
                            error = (error ERR_TCP_SERVER_TO_CLIENT_RETRANSMISSION "(" (t-server_transmitted_t[session]) " s)" ",");
                            nok = 1
                        }

                        if (sequence_range[2] < sequence_range[1]) {
                            error = (error ERR_TCP_UNEXPECTED_TRANSMISSION_SERVER_TO_CLIENT_SEQUENCE ",");
                            nok = 1;
                        }

                        if (nok == 0) {
                            server_transmitted[session] = sequence_range[2];
                        }

                        server_transmitted_t[session] = t;
                        server_transmitted_part_t[session][sequence_range[2]] = t;
                        
                    } else if (sequence_type != "") {
                        error = (error ERR_TCP_UNEXPECTED_TRANSMISSION_SERVER_TO_CLIENT_SEQUENCE ",");
                    }

                    if (ack == "") {
                        error = (error ERR_TCP_UNEXPECTED_TRANSMISSION_SERVER_TO_CLIENT_ACK ",");
                    } else {
                        jitter_t = ""
                        for (i = client_transmitted[session]+1; client_jitter_transmitted[session][i] == 1; i++) {
                            client_transmitted[session]++;
                            if (client_jitter_t[session][i] != "" && (jitter_t == "" || client_jitter_t[session][i] > jitter_t)) {
                                jitter_t = client_jitter_t[session][i];
                            }
                        }

                        if (jitter_t != "") {
                            error = (error ERR_TCP_SERVER_TO_CLIENT_RETRANSMISSION_DELAY "(" (t-jitter_t) " s)" ",");
                            session_retransmission_delay[session] = session_retransmission_delay[session] + (t-jitter_t);
                        }

                        if (ack > client_transmitted[session]) {
                            error = (error ERR_TCP_UNEXPECTED_TRANSMISSION_SERVER_TO_CLIENT_ACK ",");
                        }

                        if (ack < client_transmitted[session]) {
                            # error = (error ERR_TCP_TRANSMISSION_SERVER_TO_CLIENT_NOT_ENOUGH_ACKNOWLEDGE ",");
                            # possibly due to big window size
                        }

                        if (last_server_ack[session][ack] != 1 && (t - client_transmitted_t[session]) > MAX_ALLOWED_LATENCY) {
                            error = (error ERR_TCP_LATENCY "(" (t-client_transmitted_t[session]) " s)" ",");
                        }

                        if (last_server_ack[session][ack] != 1 && client_transmitted_part_t[session][ack] != "" && (t - client_transmitted_part_t[session][ack]) > MAX_ALLOWED_LATENCY) {
                            error = (error ERR_TCP_LATENCY "(" (t-client_transmitted_part_t[session][ack]) " s)" ",");
                        }

                        if (last_server_ack[session][ack] == 1 && sequence_type == "") {
                            error = (error ERR_TCP_SERVER_TO_CLIENT_REQUESTED_RETRANSMISSION "(delay " (t-client_transmitted_part_t[session][ack]) " s)" ",");
                            session_retransmission_delay[session] = session_retransmission_delay[session] + (t-client_transmitted_part_t[session][ack]);
                        }
                        last_server_ack[session][ack] = 1;

                        expected_ack_from_client[session] = ack;
                    }
                }
            } else if (flags == "F.") {
                nok = 0;

                if (mode == "client-to-server") {
                    if (sequence_type != "absolute" && sequence != client_transmitted[session]) {
                        warn = (warn ERR_TCP_UNEXPECTED_FIN_CLIENT_TO_SERVER_SEQUENCE ",");
                        nok = 1;
                    }

                    if (ack > server_transmitted[session]) {
                        warn = (warn ERR_TCP_UNEXPECTED_FIN_CLIENT_TO_SERVER_ACK ",");
                    }

                    if (ack < server_transmitted[session]) {
                        warn = (warn ERR_TCP_FIN_CLIENT_TO_SERVER_NOT_ENOUGH_ACKNOWLEDGE ",");
                    }

                    if (nok == 0) {
                        session_state[session] = "fin-sent";
                        fin_sent[session] = t;
                        fin_initiator[session] = "client";
                    }
                } else {
                    if (sequence_type != "absolute" && sequence != server_transmitted[session]) {
                        warn = (warn ERR_TCP_UNEXPECTED_FIN_SERVER_TO_CLIENT_SEQUENCE ",");
                        nok = 1;
                    }

                    if (ack > client_transmitted[session]) {
                        warn = (warn ERR_TCP_UNEXPECTED_FIN_SERVER_TO_CLIENT_ACK ",");
                    }

                    if (ack < client_transmitted[session]) {
                        warn = (warn ERR_TCP_FIN_SERVER_TO_CLIENT_NOT_ENOUGH_ACKNOWLEDGE ",");
                    }

                    if (nok == 0) {
                        session_state[session] = "fin-sent";
                        fin_sent[session] = t;
                        fin_initiator[session] = "server";
                    }
                }

                if (nok == 0) {
                    session_duration_length = session_duration_length + 1;
                    session_duration[session_duration_length] = t;

                    retransmission_delay_length = retransmission_delay_length + 1;
                    retransmission_delay[retransmission_delay_length] = session_retransmission_delay[session];
                }
            } else {
                error = (error ERR_TCP_INVALID_FLAGS "(" flags ")" ",");
            }
        } else if (state == "fin-sent") {
            nok = 0;

            if (flags != "." || (fin_initiator[session] == "server" && mode == "server-to-client") || (fin_initiator[session] == "client" && mode == "client-to-server") ) {
                nok = 1;

                if (flags == "F." && ( (fin_initiator[session] == "server" && mode == "client-to-server") || (fin_initiator[session] == "client" && mode == "server-to-client")  )) {
                    second_nok = 0

                    if (mode == "client-to-server") {
                        second_nok = 0;

                        if (sequence_type != "absolute" && sequence != client_transmitted[session]) {
                            warn = (warn ERR_TCP_UNEXPECTED_SECOND_FIN_CLIENT_TO_SERVER_SEQUENCE ",");
                            second_nok = 1;
                        }

                        if (ack > server_transmitted[session] + 1) {
                            warn = (warn ERR_TCP_UNEXPECTED_SECOND_FIN_CLIENT_TO_SERVER_ACK ",");
                        }

                        if (ack < server_transmitted[session] + 1) {
                            warn = (warn ERR_TCP_SECOND_FIN_CLIENT_TO_SERVER_NOT_ENOUGH_ACKNOWLEDGE ",");
                        }

                        if (second_nok == 0) {
                            server_transmitted[session] = ack

                            if ((t-fin_sent[session]) > MAX_ALLOWED_LATENCY) { 
                                error = (error ERR_TCP_LATENCY "(" (t-fin_sent[session]) " s)" ","); 
                            }

                            session_state[session] = "second-fin-sent";
                            fin_sent[session] = t;
                        }
                    } else {
                        second_nok = 0;

                        if (sequence_type != "absolute" && sequence != server_transmitted[session]) {
                            warn = (warn ERR_TCP_UNEXPECTED_SECOND_FIN_SERVER_TO_CLIENT_SEQUENCE ",");
                            second_nok = 1;
                        }

                        if (ack > client_transmitted[session] + 1) {
                            warn = (warn ERR_TCP_UNEXPECTED_SECOND_FIN_SERVER_TO_CLIENT_ACK "(ack=" ack " expected_ack=" client_transmitted[session] ")" ",");
                        }

                        if (ack < client_transmitted[session] + 1) {
                            warn = (warn ERR_TCP_SECOND_FIN_SERVER_TO_CLIENT_NOT_ENOUGH_ACKNOWLEDGE ",");
                        }

                        if (second_nok == 0) {
                            client_transmitted[session] = ack
                            
                            if ((t-fin_sent[session]) > MAX_ALLOWED_LATENCY) { 
                                error = (error ERR_TCP_LATENCY "(" (t-fin_sent[session]) " s)" ","); 
                            }

                            session_state[session] = "second-fin-sent";
                            fin_sent[session] = t;
                        }
                    }
                }
                else if (flags == "F." && ((fin_initiator[session] == "server" && mode == "server-to-client") || (fin_initiator[session] == "client" && mode == "client-to-server"))) {
                    warn = (warn ERR_TCP_FIN_RETRANSMISSION "(" (t-fin_sent[session]) " s)" ",");
                } else {
                    warn = (warn ERR_TCP_FIN_INVALID_FLAGS "(" flags ")" ",");
                }
            } else if (mode == "client-to-server") {
                if (ack > server_transmitted[session] + 1) {
                    nok = 1;
                    warn = (warn ERR_TCP_FIN_RECEIVER_UNEXPECTED_ACK ",");
                }

                if (ack < server_transmitted[session] + 1) {
                    nok = 1;
                    warn = (warn ERR_TCP_FIN_RECEIVER_PENDING_ACKNOWLEDGE ",");
                } 

                if (nok == 0) {
                    server_transmitted[session] = ack
                }
            } else {
                if (ack > client_transmitted[session] + 1) {
                    nok = 1;
                    warn = (warn ERR_TCP_FIN_RECEIVER_UNEXPECTED_ACK ",");
                }

                if (ack < client_transmitted[session] + 1) {
                    nok = 1;
                    # this is OK
                }

                if (nok == 0) {
                    client_transmitted[session] = ack;
                }
            }

            if (nok == 0) {
                if ((t-fin_sent[session]) > MAX_ALLOWED_LATENCY) {
                    error = (error ERR_TCP_LATENCY "(" (t-fin_sent[session]) " s)" ",");
                }

                session_state[session] = "fin-ack";
            }
        } else if (state == "fin-ack") {
            nok = 0;
            if (flags != "F." || (fin_initiator[session] == "server" && mode == "server-to-client") || (fin_initiator[session] == "client" && mode == "client-to-server")) {
                nok = 1;
                error = (error ERR_TCP_FINACK_INVALID_FLAGS ",");
            } else {
                 if (mode == "client-to-server") {
                    nok = 0;

                    if (sequence_type != "absolute" && sequence != client_transmitted[session]) {
                        warn = (warn ERR_TCP_UNEXPECTED_SECOND_FIN_CLIENT_TO_SERVER_SEQUENCE ",");
                        nok = 1;
                    }

                    if (ack > server_transmitted[session]) {
                        warn = (warn ERR_TCP_UNEXPECTED_SECOND_FIN_CLIENT_TO_SERVER_ACK ",");
                    }

                    if (ack < server_transmitted[session]) {
                        warn = (warn ERR_TCP_SECOND_FIN_CLIENT_TO_SERVER_NOT_ENOUGH_ACKNOWLEDGE ",");
                    }

                    if (nok == 0) {
                        session_state[session] = "second-fin-sent";
                        fin_sent[session] = t;
                    }
                } else {
                    nok = 0;

                    if (sequence_type != "absolute" && sequence != server_transmitted[session]) {
                        warn = (warn ERR_TCP_UNEXPECTED_SECOND_FIN_SERVER_TO_CLIENT_SEQUENCE ",");
                        nok = 1;
                    }

                    if (ack > client_transmitted[session]) {
                        warn = (warn ERR_TCP_UNEXPECTED_SECOND_FIN_SERVER_TO_CLIENT_ACK "(ack=" ack " expected_ack=" client_transmitted[session] ")" ",");
                    }

                    if (ack < client_transmitted[session]) {
                        warn = (warn ERR_TCP_SECOND_FIN_SERVER_TO_CLIENT_NOT_ENOUGH_ACKNOWLEDGE ",");
                    }

                    if (nok == 0) {
                        session_state[session] = "second-fin-sent";
                        fin_sent[session] = t;
                    }
                }
            }
        } else if (state == "second-fin-sent") {
            nok = 0;

            if (flags != "." || (fin_initiator[session] == "server" && mode == "client-to-server") || (fin_initiator[session] == "client" && mode == "server-to-client") ) {
                nok = 1;

                if (flags == "F." && ((fin_initiator[session] == "server" && mode == "client-to-server") || (fin_initiator[session] == "client" && mode == "server-to-client"))) {
                    warn = (warn ERR_TCP_SECOND_FIN_RETRANSMISSION "(" (t-fin_sent[session]) " s)" ",");
                } else {
                    warn = (warn ERR_TCP_SECOND_FIN_INVALID_FLAGS "(" flags ")" ",");
                }
            } else if (mode == "client-to-server") {
                if (ack > server_transmitted[session] + 1) {
                    nok = 1;
                    warn = (warn ERR_TCP_SECOND_FIN_RECEIVER_UNEXPECTED_ACK ",");
                }

                if (ack < server_transmitted[session] + 1) {
                    nok = 1;
                    warn = (warn ERR_TCP_SECOND_FIN_RECEIVER_PENDING_ACKNOWLEDGE ",");
                } 

                if (nok == 0) {
                    server_transmitted[session] = ack
                }
            } else {
                if (ack > client_transmitted[session] + 1) {
                    nok = 1;
                    warn = (warn ERR_TCP_SECOND_FIN_RECEIVER_UNEXPECTED_ACK ",");
                }

                if (ack < client_transmitted[session] + 1) {
                    nok = 1;
                    # this is OK
                }

                if (nok == 0) {
                    client_transmitted[session] = ack;
                }
            }

            if (nok == 0) {
                if ((t-fin_sent[session]) > MAX_ALLOWED_LATENCY) {
                    error = (error ERR_TCP_LATENCY "(" (t-fin_sent[session]) " s)" ",");
                }

                session_state[session] = "closed";

                session_until_closure_duration_length = session_until_closure_duration_length + 1;
                session_until_closure_duration[session_until_closure_duration_length] = t;
            }
        } else if (state == "closed") {
            warn = (warn ERR_TCP_PACKET_ON_CLOSED_CONNECTION);
        }

        sub(/,$/,"",error);
        sub(/,$/,"",warn);

        if (error != "") {
            if (warn == "") {
                print "LINE=" NR " " "T=" t " " "SENDER=" sender " " "RECEIVER=" receiver " " "SESSION=" session " " "ERR=" error;
            } else {
                print "LINE=" NR " " "T=" t " " "SENDER=" sender " " "RECEIVER=" receiver " " "SESSION=" session " " "ERR=" error " " "WARN=" warn;
            }
        } else if (warn != "") { 
            print "LINE=" NR " " "T=" t " " "SENDER=" sender " " "RECEIVER=" receiver " " "SESSION=" session " " "WARN=" warn;
        }

        #print "-- LINE=" NR " " "server_transmitted=" server_transmitted[session]
    }
}

END {
    print "";
    print "------------------------------";
    print "";

    print "Number of sessions: " session_duration_length;
    
    if (session_duration_length > 0) {
        sum = 0;
        for (i=1; i<=session_duration_length; i++) {
            sum = sum + session_duration[i];
        }

        asort(session_duration);
        print "> Minimum Duration: " session_duration[1] " s";
        print "> Maximum Duration: " session_duration[session_duration_length] " s";
        print "> Avg Duration: " (sum / session_duration_length) " s";
        print "> Median Duration: " (session_duration[int(session_duration_length/2)]) " s";
        print "> Upper 90% Duration: " (session_duration[int(session_duration_length*0.9)]) " s";
        print "> Upper 99% Duration: " (session_duration[int(session_duration_length*0.99)]) " s";
        print "";
    }

    if (session_until_closure_duration_length > 0) {
        sum = 0;
        for (i=1; i<=session_until_closure_duration_length; i++) {
            sum = sum + session_until_closure_duration[i];
        }

        asort(session_until_closure_duration);
        print "> Minimum Until Full Termination Duration: " session_until_closure_duration[1] " s";
        print "> Maximum Until Full Termination Duration: " session_until_closure_duration[session_until_closure_duration_length] " s";
        print "> Avg Until Full Termination Duration: " (sum / session_until_closure_duration_length) " s";
        print "> Median Until Full Termination Duration: " (session_until_closure_duration[int(session_until_closure_duration_length/2)]) " s";
        print "> Upper 90% Until Full Termination Duration: " (session_until_closure_duration[int(session_until_closure_duration_length*0.9)]) " s";
        print "> Upper 99% Until Full Termination Duration: " (session_until_closure_duration[int(session_until_closure_duration_length*0.99)]) " s";
        print "";
    }

    if (retransmission_delay_length > 0) {
        sum = 0;
        for (i=1; i<=retransmission_delay_length; i++) {
            sum = sum + retransmission_delay[i];
        }

        asort(retransmission_delay);
        print "> Minimum Retransmission Caused Delay: " retransmission_delay[1] " s";
        print "> Maximum Retransmission Caused Delay: " retransmission_delay[retransmission_delay_length] " s";
        print "> Avg Retransmission Caused Delay: " (sum / retransmission_delay_length) " s";
        print "> Median Retransmission Caused Delay: " (retransmission_delay[int(retransmission_delay_length/2)]) " s";
        print "> Upper 90% Retransmission Caused Delay: " (retransmission_delay[int(retransmission_delay_length*0.9)]) " s";
        print "> Upper 99% Retransmission Caused Delay: " (retransmission_delay[int(retransmission_delay_length*0.99)]) " s";
        print "";
    }

    unterminated_sessions = 0;
    unterminated_reason_length = 0;
    for (i=1; i<=all_sessions_length; i++) {
        session = all_sessions[i];
        state = session_state[session];

        if (state != "closed") {
            unterminated_sessions = unterminated_sessions + 1;

            found = 0;
            for (j=1; j<=untermated_reason_length; j++) {
                if (unterminated_reason[j] == state) {
                    found = 1;
                    break;
                }
            }

            if (found == 0) {
                unterminated_reason_length = unterminated_reason_length + 1;
                unterminated_reason[unterminated_reason_length] = state;
                unterminated_reason_count[state] = 1;
            } else {
                unterminated_reason_count[state] = unterminated_reason_count[state] + 1;
            }
        }
    }

    print "> Unterminated Sessions: " unterminated_sessions;
    for (i=1; i<=unterminated_reason_length; i++) {
        print ">> State: " unterminated_reason[i] ": " unterminated_reason_count[unterminated_reason[i]];
    }
    print "";
}


