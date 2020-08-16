#include <iostream>
#include <string>
#include <map>
#include <limits>
#include <vector>
#include <sstream>
#include <locale>
#include <codecvt>
#include <fstream>
#include <chrono>
#include <cstring>

using namespace std;

#define BUCKET 1024

const wchar_t keep_commands[] = {
  'a', 'b', 'c',
  'd', 'e', 'f',
  'g', 'h', 'i',
};

const wchar_t insert_commands[] = {
  'j', 'k', 'l',
  'm', 'o', 'p',
  'q', 'r', 's',
};

const wchar_t delete_commands[] = {
  't', 'u' , 'v',
  'w', 'x', 'y',
  'z', '0', '1',
};

const wchar_t replace_commands[] = {
  '2', '3', '4',
  '5', '6', '7',
  '8', '9', 'A',
};

size_t tick_count() {
  using namespace std::chrono;
  return duration_cast<milliseconds>(steady_clock::now().time_since_epoch()).count();
}

void report(string const& item, size_t value, bool increment=true) {
  static size_t last_tick = 0;
  static map<string, size_t> values;

  if (increment) {
    auto i = values.find(item);
    if (i != values.end()) {
      value = value + i->second;
    }
  }
  values[item] = value;

  size_t now = tick_count();
  if (now - last_tick > 2000) {
    last_tick = now;
    cerr << "----------------" << endl;
    for (auto i = values.begin(); i != values.end(); ++i) {
      cerr << i->first << ": " << i->second << endl;
    }
  }
}

size_t itoa_length(size_t len) {
  if (len < 10) {
    return 1;
  } else if (len < 100) {
    return 2;
  } else if (len < 1000) {
    return 3;
  } else if (len < 10000) {
    return 4;
  } else if (len < 100000) {
    return 5;
  } else if (len < 1000000) {
    return 6;
  } else if (len < 10000000) {
    return 7;
  } else if (len < 100000000) {
    return 8;
  } else if (len < 1000000000) {
    return 9;
  } else {
    throw runtime_error("out of range");
  }
}

size_t estimate_insert_command_length(size_t length) {
  return 1 + itoa_length(length) + length;
}

void fill_insert_command(wstringstream& result, wstring const& s, size_t i, size_t length) {
  result.put(insert_commands[itoa_length(length) - 1]);
  result << length;
  result.write(s.c_str() + i, length);
}

size_t estimate_keep_command_length(size_t length) {
  return 1 + itoa_length(length);
}

void fill_keep_command(wstringstream& result, size_t length) {
  result.put(keep_commands[itoa_length(length) - 1]);
  result << length;
}

size_t estimate_delete_command_length(size_t length) {
  return 1 + itoa_length(length);
}

void fill_delete_command(wstringstream& result, size_t length) {
  result.put(delete_commands[itoa_length(length) - 1]);
  result << length;
}

size_t estimate_replace_command_length(size_t length) {
  return 1 + itoa_length(length) + length;
}

void fill_replace_command(wstringstream& result, wstring const& s, size_t i, size_t length) {
  result.put(replace_commands[itoa_length(length) - 1]);
  result << length;
  result.write(s.c_str() + i, length);
}

size_t calculate_rec(
  wstring const& x,
  wstring const& y,
  size_t i,
  size_t j,
  size_t x_end,
  size_t y_end,
  size_t x_start,
  size_t y_start,
  size_t** d,
  wstringstream *str_result,
  size_t target_c,
  size_t depth,
  size_t block) {

  if (i >= x_end) {
    if (j >= y_end) {
      return 0;
    }

    // insert cmd
    size_t result = estimate_insert_command_length(y_end - j);

    if (str_result != NULL && result == target_c) {
      fill_insert_command(*str_result, y, j, y_end - j);
    }

    return result;
  }

  if (j >= y_end) {
    // delete cmd
    size_t result = estimate_delete_command_length(x_end - i);

    if (str_result != NULL && result == target_c) {
      fill_delete_command(*str_result, x_end - i);
    }

    return result;
  }

  if (str_result == NULL) {
    if (d[i - x_start][j - y_start]) {
      return d[i - x_start][j - y_start];
    } else {
    }
  }

  size_t c = numeric_limits<size_t>::max();

  size_t max_equal = 0;
  for (size_t k = 1; k <= min(x_end - i, y_end - j); k++) {
    if (x[i + k -1] == y[j + k - 1]) {
      max_equal = max_equal + 1;
    } else {
      break;
    }
  }

  // calculate keeps
  if (max_equal > 0) {
    size_t local_cost = estimate_keep_command_length(max_equal);
    size_t next_cost = calculate_rec(x, y, i + max_equal, j + max_equal, x_end, y_end, x_start, y_start, d, NULL, numeric_limits<size_t>::max(), depth + 1, block);

    if (next_cost != numeric_limits<size_t>::max()) {
      size_t new_cost = local_cost + next_cost;

      if (str_result != NULL && new_cost == target_c) {
        fill_keep_command(*str_result, max_equal);
        calculate_rec(x, y, i + max_equal, j + max_equal, x_end, y_end, x_start, y_start, d, str_result, target_c - local_cost, depth + 1, block);
        return new_cost;
      }

      if (new_cost < c) {
        c = new_cost;
      }
    }
  }

  // calculate deletes
  for (size_t k = 1; k <= x_end - i; k++) {
    size_t local_cost = estimate_delete_command_length(k);
    size_t next_cost = calculate_rec(x, y, i + k, j, x_end, y_end, x_start, y_start, d, NULL, numeric_limits<size_t>::max(), depth + 1, block);

    if (next_cost != numeric_limits<size_t>::max()) {
      size_t new_cost = local_cost + next_cost;

      if (str_result != NULL && new_cost == target_c) {
        fill_delete_command(*str_result, k);
        calculate_rec(x, y, i + k, j, x_end, y_end, x_start, y_start, d, str_result, target_c - local_cost, depth + 1, block);
        return new_cost;
      }

      if (new_cost < c) {
        c = new_cost;
      }
    } else {
      break;
    }
  }

  // calculate inserts
  for (size_t k = 1; k <= y_end - j; k++) {
    size_t local_cost = estimate_insert_command_length(k);
    size_t next_cost = calculate_rec(x, y, i, j + k, x_end, y_end, x_start, y_start, d, NULL, numeric_limits<size_t>::max(), depth + 1, block);

    if (next_cost != numeric_limits<size_t>::max()) {
      size_t new_cost = local_cost + next_cost;

      if (str_result != NULL && new_cost == target_c) {
        fill_insert_command(*str_result, y, j, k);
        calculate_rec(x, y, i, j + k, x_end, y_end, x_start, y_start, d, str_result, target_c - local_cost, depth + 1, block);
        return new_cost;
      }

      if (new_cost < c) {
        c = new_cost;
      }
    } else {
      break;
    }
  }

  // calculate for replace
  for (size_t k = 1; k <= min(x_end - i, y_end - j); k++) {
    size_t local_cost = estimate_replace_command_length(k);
    size_t next_cost = calculate_rec(x, y, i + k, j + k, x_end, y_end, x_start, y_start, d, NULL, numeric_limits<size_t>::max(), depth + 1, block);

    if (next_cost != numeric_limits<size_t>::max()) {
      size_t new_cost = local_cost + next_cost;

      if (str_result != NULL && new_cost == target_c) {
        fill_replace_command(*str_result, y, j, k);
        calculate_rec(x, y, i + k, j + k, x_end, y_end, x_start, y_start, d, str_result, target_c - local_cost, depth + 1, block);
        return new_cost;
      }

      if (new_cost < c) {
        c = new_cost;
      }
    } else {
      break;
    }
  }

  if (str_result == NULL) {
    d[i - x_start][j - y_start] = c;
  }

  return c;
}

size_t** make_table(size_t x_length, size_t y_length) {
  static size_t* raw_d = NULL;
  static size_t full_size = 0;

  static size_t** d = NULL;
  static size_t x_size = 0;
  static size_t y_size = 0;

  size_t size = x_length * y_length;
  if (size > full_size) {
    if (raw_d != NULL) {
      free(raw_d);

      if (d != NULL) {
        free(d);
      }

      d = NULL;
      x_size = 0;
      y_size = 0;
    }

    raw_d = (size_t*)malloc(size * sizeof(size_t));
    full_size = size;
  }

  if (x_length > x_size) {
    if (d != NULL) {
      free(d);
    }

    d = (size_t**)malloc(x_length * sizeof(size_t*));
    x_size = x_length;
    y_size = 0;
  }

  if (y_length > y_size) {
    for (size_t i = 0; i < x_length; i++) {
      d[i] = raw_d + (i * y_length);
    }
    y_size = y_length;
  }

  memset(raw_d, 0, full_size * sizeof(size_t));

  return d;
}

void calculate_strings(wstringstream& result, wstring const& x, wstring const& y, size_t** d, size_t i, size_t j, size_t x_end, size_t y_end, size_t block) {
  size_t cost = calculate_rec(x, y, i, j, x_end, y_end, i, j, d, NULL, numeric_limits<size_t>::max(), 0, block);
  calculate_rec(x, y, i, j, x_end, y_end, i, j, d, &result, cost, 0, block);
}

wstring calculate(wstring const& x, wstring const& y) {
  wstringstream result;
  size_t** d = make_table(x.length(), y.length());
  calculate_strings(result, x, y, d, 0, 0, x.length(), y.length(), 0);
  return result.str();
}

wstring calculate_blocked(wstring const& x, wstring const& y, size_t block) {
  size_t i = 0;
  size_t j = 0;
  wstringstream result;

  size_t index = 0;

  while (i < x.length() || j < y.length()) {
    size_t actual_i = min(i, x.length());
    size_t actual_j = min(j, y.length());
    size_t actual_i_end = min(block + i, x.length());
    size_t actual_j_end = min(block + j, y.length());

    size_t** d = make_table(actual_i_end - actual_i, actual_j_end - actual_j);

    calculate_strings(result, x, y, d, actual_i, actual_j, actual_i_end, actual_j_end, index);

    i = i + block;
    j = j + block;
    index = index + 1;

    //report("progress", (i * 100) / max(x.length(), y.length()), false);
  }

  return result.str();
}

wstring make_wstring(string const& s) {
  wstring_convert<codecvt_utf8_utf16<wchar_t>> converter;
  return converter.from_bytes(s);
}

std::wstring readFile(string const& filename)
{
  std::wifstream wif(filename);

  if (!wif.is_open()) {
    char buff[4096];
    sprintf(buff, "failed to open file '%s'", filename.c_str());
    throw runtime_error(buff);
  }

  wif.imbue(locale("en_US.UTF-8"));

  wif.seekg(0, std::ios::end);
  size_t size = wif.tellg();
  std::wstring buffer(size, ' ');
  wif.seekg(0);
  size_t read = 0;

  while (read < size) {
    if (wif.bad()) {
      throw runtime_error("failed to read from input device");
    }

    if (wif.eof()) {
      return buffer.substr(0, read);
    }

    if (wif.fail()) {
      wif.seekg(read + 1);
      read = read + 1;
      size = size - 1;
    }

    wif.read(&buffer[read], size);
    read = read + wif.gcount();
    size = size - read;
  }

  return buffer;
}

wstring calculate_files(string const &x, string const& y, size_t block) {
  wstring left_file = readFile(x);
  wstring right_file = readFile(y);

  return calculate_blocked(left_file, right_file, block);
}

wstring calculate_file(string const& x) {
  wstring left_file = L"";
  wstring right_file = readFile(x);

  return calculate_blocked(left_file, right_file, BUCKET);
}

size_t read_command_size(wstring const& str, size_t i, size_t len) {
  size_t result = 0;

  for (size_t j = 0; j < len; j++) {
    result = result * 10 + (str[i + j] - '0');
  }

  return result;
}

bool is_keep_command(wstring const& str, size_t i, size_t& len, size_t& next_i) {
  for (size_t j = 0; j < sizeof(keep_commands) / sizeof(wchar_t); j++) {
    if (keep_commands[j] == str[i]) {
      len = read_command_size(str, i + 1, j + 1);
      next_i = i + 2 + j;

      return true;
    }
  }

  return false;
}

bool is_insert_command(wstring const& str, size_t i, size_t& len, size_t& str_begin, size_t& next_i) {
  for (size_t j = 0; j < sizeof(insert_commands) / sizeof(wchar_t); j++) {
    if (insert_commands[j] == str[i]) {
      len = read_command_size(str, i + 1, j + 1);
      str_begin = i + 2 + j;
      next_i = i + 2 + j + len;

      return true;
    }
  }

  return false;
}

bool is_delete_command(wstring const& str, size_t i, size_t& len, size_t& next_i) {
  for (size_t j = 0; j < sizeof(delete_commands) / sizeof(wchar_t); j++) {
    if (delete_commands[j] == str[i]) {
      len = read_command_size(str, i + 1, j + 1);
      next_i = i + 2 + j;

      return true;
    }
  }

  return false;
}

bool is_replace_command(wstring const& str, size_t i, size_t& len, size_t& str_begin, size_t& next_i) {
  for (size_t j = 0; j < sizeof(replace_commands) / sizeof(wchar_t); j++) {
    if (replace_commands[j] == str[i]) {
      len = read_command_size(str, i + 1, j + 1);
      str_begin = i + 2 + j;
      next_i = i + 2 + j + len;

      return true;
    }
  }

  return false;
}

char get_command(wstring const& str, size_t i, size_t& arg, pair<size_t, size_t>& string_arg, size_t& next_i) {
  if (is_keep_command(str, i, arg, next_i)) {
    return 'K';
  }

  if (is_insert_command(str, i, string_arg.second, string_arg.first, next_i)) {
    arg = string_arg.second;
    return 'I';
  }

  if (is_delete_command(str, i, arg, next_i)) {
    return 'D';
  }

  if (is_replace_command(str, i, string_arg.second, string_arg.first, next_i)) {
    arg = string_arg.second;
    return 'R';
  }

  throw runtime_error("unknown command sequence");
}

void merge_command(char command, size_t& arg, vector< pair<size_t, size_t> >& string_arg_list, size_t new_arg, pair<size_t, size_t> new_string_arg) {
  if (command == 'K') {
    arg = arg + new_arg;
  } else if (command == 'I') {
    arg = arg + new_arg;
    string_arg_list.push_back(new_string_arg);
  } else if (command == 'D') {
    arg = arg + new_arg;
  } else if (command == 'R') {
    arg = arg + new_arg;
    string_arg_list.push_back(new_string_arg);
  } else {
    throw runtime_error("unknown command sequence");
  }
}

void inject_command(wstringstream& result, wstring const& s, char command, size_t arg, vector< pair<size_t, size_t> > const& string_arg) {
  if (command == '\0') {
    return;
  }

  if (command == 'K') {
    fill_keep_command(result, arg);
  } else if (command == 'I') {
    result.put(insert_commands[itoa_length(arg) - 1]);
    result << arg;

    for (size_t i = 0; i < string_arg.size(); i++) {
      result.write(s.c_str() + string_arg[i].first, string_arg[i].second);
    }
  } else if (command == 'D') {
    fill_delete_command(result, arg);
  } else if (command == 'R') {
    result.put(replace_commands[itoa_length(arg) - 1]);
    result << arg;

    for (size_t i = 0; i < string_arg.size(); i++) {
      result.write(s.c_str() + string_arg[i].first, string_arg[i].second);
    }
  } else {
    throw runtime_error("unknown command sequence");
  }
}

wstring compress_adjacent_commands(wstring const& str) {
  wstringstream result;
  char last_command = '\0';
  size_t last_command_integer_arg = 0;
  vector< pair<size_t, size_t> > last_command_string_arg;
  size_t i = 0;

  while (i < str.length()) {
    size_t next_i;
    size_t arg;
    pair<size_t, size_t> string_arg;

    char command = get_command(str, i, arg, string_arg, next_i);

    if (command != last_command) {
      inject_command(result, str, last_command, last_command_integer_arg, last_command_string_arg);
      last_command = command;
      last_command_integer_arg = arg;
      last_command_string_arg.clear();
      last_command_string_arg.push_back(string_arg);
    } else {
      merge_command(command, last_command_integer_arg, last_command_string_arg, arg, string_arg);
    }

    i = next_i;
  }

  inject_command(result, str, last_command, last_command_integer_arg, last_command_string_arg);

  return result.str();
}

void print_usage() {
}

int main(int argc, char**argv) {
  if (argc == 3 || argc == 4 || argc == 5) {
    if (argc == 4) {
      if (!strcmp(argv[1], "debug")) {
        wcout << compress_adjacent_commands(calculate(make_wstring(argv[2]), make_wstring(argv[3])));
        return 0;
      }
      size_t block = atol(argv[3]);
      wcout << compress_adjacent_commands(calculate_files(argv[1], argv[2], block));
    } else if (argc == 5) {
      if (!strcmp(argv[1], "debug")) {
        size_t block = atol(argv[4]);
        wcout << compress_adjacent_commands(calculate_blocked(make_wstring(argv[2]), make_wstring(argv[3]), block));
      }
    } else {
      if (!strcmp(argv[1], "debug")) {
        wcout << compress_adjacent_commands(calculate(L"", make_wstring(argv[2])));
        return 0;
      }
      wcout << compress_adjacent_commands(calculate_files(argv[1], argv[2], BUCKET));
    }
  } else if (argc == 2) {
    wcout << compress_adjacent_commands(calculate_file(argv[1]));
  } else {
    print_usage();
  }
}
