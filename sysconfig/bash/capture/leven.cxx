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

struct command {
  char cmd; // K(Keep), I(Insert), D(Delete), R(Replace)
  size_t arg1; // K(length), I(start index), D(length), R(start index)
  size_t arg2; // K(unused), I(length), D(unused), R(length)
  size_t cost; // dynamic programming cost

  bool valid() const {
    return cmd != '\0';
  }

  void fill(wstringstream& result, wstring const& other) const {
    switch (this->cmd) {
      case 'K':
        result.put(keep_commands[itoa_length(this->arg1) - 1]);
        result << this->arg1;
        break;

      case 'I':
        result.put(insert_commands[itoa_length(this->arg2) - 1]);
        result << this->arg2;
        result.write(other.c_str() + this->arg1, this->arg2);
        break;

      case 'D':
        result.put(delete_commands[itoa_length(this->arg1) - 1]);
        result << this->arg1;
        break;

      case 'R':
        result.put(replace_commands[itoa_length(this->arg2) - 1]);
        result << this->arg2;
        result.write(other.c_str() + this->arg1, this->arg2);
        break;

      default:
        throw runtime_error("unsupported command in command::fill");
    }
  }

  static command keep(size_t cost, size_t length) {
    return command('K', cost, length, 0);
  }

  static command insert(size_t cost, size_t index, size_t length) {
    return command('I', cost, index, length);
  }

  static command remove(size_t cost, size_t length) {
    return command('D', cost, length, 0);
  }

  static command replace(size_t cost, size_t index, size_t length) {
    return command('R', cost, index, length);
  }

  static command empty() {
    return command('\0', numeric_limits<size_t>::max(), 0, 0);
  }

private:
  command(char cmd, size_t cost, size_t arg1, size_t arg2) {
    this->cmd = cmd;
    this->cost = cost;
    this->arg1 = arg1;
    this->arg2 = arg2;
  }
};

struct command_set {
  vector< command > commands;

  void fill(wstringstream& result, wstring const& other) {
    for (auto i = commands.begin(); i != commands.end(); ++i) {
      i->fill(result, other);
    }
  }

  void add(command const& x) {
    if (commands.empty()) {
      commands.push_back(x);
      return;
    }

    command& last = commands.back();

    if (last.cmd != x.cmd) {
      commands.push_back(x);
      return;
    }

    bool merged = false;

    switch (x.cmd) {
      case 'K':
        last.arg1 += x.arg1;
        merged = true;
        break;

      case 'I':
        if (x.arg1 == (last.arg1 + last.arg2)) {
          last.arg2 += x.arg2;
          merged = true;
        }
        break;

      case 'D':
        last.arg1 += x.arg1;
        merged = true;
        break;

      case 'R':
        if (x.arg1 == (last.arg1 + last.arg2)) {
          last.arg2 += x.arg2;
          merged = true;
        }
        break;

      default:
        throw runtime_error("invalid command at command_set::add");
    }

    if (!merged) {
      commands.push_back(x);
    }
  }
};

void fill_calculate_rec_result(
  command_set& result,
  size_t i,
  size_t j,
  size_t x_end,
  size_t y_end,
  size_t x_start,
  size_t y_start,
  command** d) {

  if (i >= x_end) {
    if (j >= y_end) {
      return;
    }

    // insert cmd
    result.add(command::insert(0, j, y_end - j));
    return;
  }

  if (j >= y_end) {
    // delete cmd
    result.add(command::remove(0, x_end - i));
    return;
  }

  command c = d[i - x_start][j - y_start];
  //cout << "get(" << i - x_start << ", " << j - y_start << ") = " << c.cost << ", valid=" << c.valid() << ", i=" << i << ", j=" << j << ", x_end=" << x_end << ", y_end=" << y_end << endl;
  if (!c.valid()) {
    throw runtime_error("bad memoize detected!");
  }

  result.add(c);

  switch (c.cmd) {
    case 'K':
      fill_calculate_rec_result(result, i + c.arg1, j + c.arg1, x_end, y_end, x_start, y_start, d);
      break;

    case 'I':
      fill_calculate_rec_result(result, i, j + c.arg2, x_end, y_end, x_start, y_start, d);
      break;

    case 'D':
      fill_calculate_rec_result(result, i + c.arg1, j, x_end, y_end, x_start, y_start, d);
      break;

    case 'R':
      fill_calculate_rec_result(result, i + c.arg2, j + c.arg2, x_end, y_end, x_start, y_start, d);
      break;

    default:
      throw runtime_error("command not detected while rebuilding memoize");
  }
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
  command** d,
  size_t depth,
  size_t block) {

  if (i >= x_end) {
    if (j >= y_end) {
      return 0;
    }

    // insert cmd
    return y_end - j;
  }

  if (j >= y_end) {
    // delete cmd
    return x_end - i;
  }

  if (d[i - x_start][j - y_start].valid()) {
    return d[i - x_start][j - y_start].cost;
  }

  command c = command::empty();

  // calculate keeps
  if (x[i] == y[j]) {
    size_t new_cost = calculate_rec(x, y, i + 1, j + 1, x_end, y_end, x_start, y_start, d, depth + 1, block);

    if (new_cost < c.cost) {
      c = command::keep(new_cost, 1);
    }
  }

  // calculate deletes
  size_t new_cost = 1 + calculate_rec(x, y, i + 1, j, x_end, y_end, x_start, y_start, d, depth + 1, block);
  if (new_cost < c.cost) {
    c = command::remove(new_cost, 1);
  }

  // calculate inserts
  new_cost = 1 + calculate_rec(x, y, i, j + 1, x_end, y_end, x_start, y_start, d, depth + 1, block);
  if (new_cost < c.cost) {
    c = command::insert(new_cost, j, 1);
  }

  // calculate for replace
  if (x[i] != y[j]) {
    new_cost = 1 + calculate_rec(x, y, i + 1, j + 1, x_end, y_end, x_start, y_start, d, depth + 1, block);

    if (new_cost < c.cost) {
      c = command::replace(new_cost, j, 1);
    }
  }

  d[i - x_start][j - y_start] = c;
  //cout << "set(" << i - x_start << "," << j - y_start << ") = " << c.cost << endl;

  return c.cost;
}

command** make_table(size_t x_length, size_t y_length) {
  static command* raw_d = NULL;
  static size_t full_size = 0;

  static command** d = NULL;
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

    raw_d = (command*)malloc(size * sizeof(command));
    full_size = size;
  }

  if (x_length > x_size) {
    if (d != NULL) {
      free(d);
    }

    d = (command**)malloc(x_length * sizeof(command*));
    x_size = x_length;
    y_size = 0;
  }

  if (y_length > y_size) {
    for (size_t i = 0; i < x_length; i++) {
      d[i] = raw_d + (i * y_length);
    }
    y_size = y_length;
  }

  memset(raw_d, 0, full_size * sizeof(command));

  return d;
}

void calculate_strings(command_set& result, wstring const& x, wstring const& y, command** d, size_t i, size_t j, size_t x_end, size_t y_end, size_t block) {
  calculate_rec(x, y, i, j, x_end, y_end, i, j, d, 0, block);
  fill_calculate_rec_result(result, i, j, x_end, y_end, i, j, d);
}

wstring calculate(wstring const& x, wstring const& y) {
  wstringstream result;
  command_set cmd_result;
  command** d = make_table(x.length(), y.length());
  calculate_strings(cmd_result, x, y, d, 0, 0, x.length(), y.length(), 0);
  cmd_result.fill(result, y);
  return result.str();
}

wstring calculate_blocked(wstring const& x, wstring const& y, size_t block) {
  size_t i = 0;
  size_t j = 0;
  wstringstream result;
  command_set cmd_result;

  size_t index = 0;

  while (i < x.length() || j < y.length()) {
    size_t actual_i = min(i, x.length());
    size_t actual_j = min(j, y.length());
    size_t actual_i_end = min(block + i, x.length());
    size_t actual_j_end = min(block + j, y.length());

    command** d = make_table(actual_i_end - actual_i, actual_j_end - actual_j);

    //cout << "------------------- block=" << index << endl;

    calculate_strings(cmd_result, x, y, d, actual_i, actual_j, actual_i_end, actual_j_end, index);

    i = i + block;
    j = j + block;
    index = index + 1;

    //report("progress", (i * 100) / max(x.length(), y.length()), false);
  }

  cmd_result.fill(result, y);
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

void print_usage() {
  cout << "./leven <fname>" << endl;
  cout << "./leven <fname> <fname>" << endl;
  cout << "./leven <fname> <fname> <block size>" << endl;
}

int main(int argc, char**argv) {
  if (argc == 3 || argc == 4 || argc == 5) {
    if (argc == 4) {
      if (!strcmp(argv[1], "debug")) {
        wcout << calculate(make_wstring(argv[2]), make_wstring(argv[3]));
        return 0;
      }
      size_t block = atol(argv[3]);
      wcout << calculate_files(argv[1], argv[2], block);
    } else if (argc == 5) {
      if (!strcmp(argv[1], "debug")) {
        size_t block = atol(argv[4]);
        wcout << calculate_blocked(make_wstring(argv[2]), make_wstring(argv[3]), block);
      }
    } else {
      if (!strcmp(argv[1], "debug")) {
        wcout << calculate(L"", make_wstring(argv[2]));
        return 0;
      }
      wcout << calculate_files(argv[1], argv[2], BUCKET);
    }
  } else if (argc == 2) {
    wcout << calculate_file(argv[1]);
  } else {
    print_usage();
  }
}
