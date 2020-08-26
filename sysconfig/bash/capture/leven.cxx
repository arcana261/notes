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
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>

using namespace std;

#define BUCKET 1024

void write_size(size_t size) {
  if (size <= 0x7F) {
    uint8_t x = (uint8_t)size;
    cout.write((char*)&x, 1);
  } else {
    uint8_t x = (uint8_t)((size & 0x7F) | 0x80);
    cout.write((char*)&x, 1);
    write_size(size >> 7);
  }
}

size_t estimate_size(size_t size) {
  if (size <= 0x7F) {
    return 1;
  } else {
    return 1 + estimate_size(size >> 7);
  }
}

#define KEEP_COMMAND 'K'
#define INSERT_COMMAND 'I'
#define DELETE_COMMAND 'D'
#define REPLACE_COMMAND 'R'

void write_cmd(char cmd) {
  cout.write(&cmd, 1);
}

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

struct command {
  char cmd; // K(Keep), I(Insert), D(Delete), R(Replace)
  size_t arg1; // K(length), I(start index), D(length), R(start index)
  size_t arg2; // K(unused), I(length), D(unused), R(length)
  size_t cost; // dynamic programming cost

  bool valid() const {
    return cmd != '\0';
  }

  void fill(const char* other, int* index) const {
    write_cmd(this->cmd);
    switch (this->cmd) {
      case KEEP_COMMAND:
        write_size(this->arg1);
        *index += this->arg1;
        cerr << "KEEP COMMAND, size= " << this->arg1 << ", index=" << *index << endl;
        break;

      case INSERT_COMMAND:
        write_size(this->arg2);
        cout.write(other + this->arg1, this->arg2);
        cerr << "INSERT COMMAND, size= " << this->arg2 << endl;
        break;

      case DELETE_COMMAND:
        write_size(this->arg1);
        *index += this->arg1;
        cerr << "DELETE COMMAND, size= " << this->arg1 << ", index=" << *index << endl;
        break;

      case REPLACE_COMMAND:
        write_size(this->arg2);
        cout.write(other + this->arg1, this->arg2);
        *index += this->arg2;
        cerr << "REPLACE COMMAND, size= " << this->arg2 << ", index=" << *index << endl;
        break;

      default:
        throw runtime_error("unsupported command in command::fill");
    }
  }

  static command keep(size_t cost, size_t length) {
    return command(KEEP_COMMAND, cost, length, 0);
  }

  static command insert(size_t cost, size_t index, size_t length) {
    return command(INSERT_COMMAND, cost, index, length);
  }

  static command remove(size_t cost, size_t length) {
    return command(DELETE_COMMAND, cost, length, 0);
  }

  static command replace(size_t cost, size_t index, size_t length) {
    return command(REPLACE_COMMAND, cost, index, length);
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

  void fill(const char* other) {
    int index = 0;
    for (auto i = commands.begin(); i != commands.end(); ++i) {
      i->fill(other, &index);
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
      case KEEP_COMMAND:
        last.arg1 += x.arg1;
        merged = true;
        break;

      case INSERT_COMMAND:
        if (x.arg1 == (last.arg1 + last.arg2)) {
          last.arg2 += x.arg2;
          merged = true;
        }
        break;

      case DELETE_COMMAND:
        last.arg1 += x.arg1;
        merged = true;
        break;

      case REPLACE_COMMAND:
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
  const char* x,
  const char* y,
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
  {
    size_t equal_range = 0;
    for (size_t k = 0; k < min(x_end - i, y_end - j); k++) {
      if (x[i + k] == y[j + k]) {
        equal_range++;
      } else {
        break;
      }
    }

    if (equal_range > 0) {
      size_t ks[3] = {1, 0, 0};
      size_t kss = 1;

      if (equal_range > 1) {
        ks[1] = equal_range / 2;
        ks[2] = equal_range;
        kss = 3;
      }

      for (size_t ki = 0; ki < kss; ki++) {
        size_t k = ks[ki];
        size_t new_cost = 1 + estimate_size(k) + calculate_rec(x, y, i + k, j + k, x_end, y_end, x_start, y_start, d, depth + 1, block);
        if (new_cost < c.cost) {
          c = command::keep(new_cost, k);
        }
      }
    }
  }

  // calculate deletes
  {
    size_t ks[3] = {1, 0, 0};
    size_t kss = 1;
    size_t k_max = x_end - i;

    if (k_max > 1) {
      ks[1] = k_max / 2;
      ks[2] = k_max;
      kss = 3;
    }

    for (size_t ki = 0; ki < kss; ki++) {
      size_t k = ks[ki];
      size_t new_cost = 1 + estimate_size(k) + calculate_rec(x, y, i + k, j, x_end, y_end, x_start, y_start, d, depth + 1, block);
      if (new_cost < c.cost) {
        c = command::remove(new_cost, k);
      }
    }
  }

  // calculate inserts
  {
    size_t ks[3] = {1, 0, 0};
    size_t kss = 1;
    size_t k_max = y_end - j;

    if ((y_end - j) > 1) {
      ks[1] = k_max / 2;
      ks[2] = k_max;
      kss = 3;
    }

    for (size_t ki = 0; ki < kss; ki++) {
      size_t k = ks[ki];
      size_t new_cost = 1 + estimate_size(k) + (k) + calculate_rec(x, y, i, j + k, x_end, y_end, x_start, y_start, d, depth + 1, block);
      if (new_cost < c.cost) {
        c = command::insert(new_cost, j, k);
      }
    }
  }

  // calculate for replace
  {
    size_t ks[3] = {1, 0, 0};
    size_t kss = 1;
    size_t k_max = min(x_end - i, y_end - j);

    if (min(x_end - i, y_end - j) > 1) {
      ks[1] = k_max / 2;
      ks[2] = k_max;
      kss = 3;
    }

    for (size_t ki = 0; ki < kss; ki++) {
      size_t k = ks[ki];
      size_t new_cost = 1 + estimate_size(k) + (k) + calculate_rec(x, y, i + k, j + k, x_end, y_end, x_start, y_start, d, depth + 1, block);
      if (new_cost < c.cost) {
        c = command::replace(new_cost, j, k);
      }
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

void calculate_strings(command_set& result, const char* x, const char* y, command** d, size_t i, size_t j, size_t x_end, size_t y_end, size_t block) {
  calculate_rec(x, y, i, j, x_end, y_end, i, j, d, 0, block);
  fill_calculate_rec_result(result, i, j, x_end, y_end, i, j, d);
}

void calculate(const char* x, const char* y, size_t x_length, size_t y_length) {
  command_set cmd_result;
  command** d = make_table(x_length, y_length);
  calculate_strings(cmd_result, x, y, d, 0, 0, x_length, y_length, 0);
  cmd_result.fill(y);
}

void calculate_blocked(const char* x, const char* y, size_t x_length, size_t y_length, size_t block) {
  size_t i = 0;
  size_t j = 0;
  command_set cmd_result;

  size_t index = 0;

  while (i < x_length || j < y_length) {
    size_t actual_i = min(i, x_length);
    size_t actual_j = min(j, y_length);
    size_t actual_i_end = min(block + i, x_length);
    size_t actual_j_end = min(block + j, y_length);

    command** d = make_table(actual_i_end - actual_i, actual_j_end - actual_j);

    //cout << "------------------- block=" << index << endl;

    calculate_strings(cmd_result, x, y, d, actual_i, actual_j, actual_i_end, actual_j_end, index);

    i = i + block;
    j = j + block;
    index = index + 1;

    //report("progress", (i * 100) / max(x.length(), y.length()), false);
  }

  cmd_result.fill(y);
}

int calculate_files(const char* x, const char* y, size_t block) {
  struct stat info;
  if (stat(x, &info) != 0) {
    cerr << "can not stat file '" << x << "'" << endl;
    return -1;
  }
  char* left_file = (char*)malloc(info.st_size);
  size_t left_size = info.st_size;
  FILE *fp = fopen(x, "rb");
  if (fp == NULL) {
    cerr << "can not open file '" << x << "' for reading" << endl;
    return -1;
  }
  size_t blocks_read = fread(left_file, info.st_size, 1, fp);
  if (blocks_read != 1) {
    cerr << "can not read file '" << x << "' for reading" << endl;
    return -1;
  }
  fclose(fp);

  if (stat(y, &info) != 0) {
    cerr << "can not stat file '" << y << "'" << endl;
    return -1;
  }
  char* right_file = (char*)malloc(info.st_size);
  size_t right_size = info.st_size;
  fp = fopen(y, "rb");
  if (fp == NULL) {
    cerr << "can not open file '" << y << "' for reading" << endl;
    return -1;
  }
  blocks_read = fread(right_file, info.st_size, 1, fp);
  if (blocks_read != 1) {
    cerr << "can not read file '" << y << "' for reading" << endl;
    return -1;
  }
  fclose(fp);

  calculate_blocked(left_file, right_file, left_size, right_size, block);

  free(left_file);
  free(right_file);

  return 0;
}

int calculate_file(const char* x) {
  struct stat info;
  if (stat(x, &info) != 0) {
    cerr << "can not stat file '" << x << "'" << endl;
    return -1;
  }
  char* left_file = (char*)malloc(info.st_size);
  size_t left_size = info.st_size;
  FILE *fp = fopen(x, "rb");
  if (fp == NULL) {
    cerr << "can not open file '" << x << "' for reading" << endl;
    return -1;
  }
  size_t blocks_read = fread(left_file, info.st_size, 1, fp);
  if (blocks_read != 1) {
    cerr << "can not read file '" << x << "' for reading" << endl;
    return -1;
  }
  fclose(fp);

  calculate_blocked("", left_file, 0, left_size, BUCKET);
  return 0;
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
        calculate(argv[2], argv[3], strlen(argv[2]), strlen(argv[3]));
        return 0;
      }
      size_t block = atol(argv[3]);
      return calculate_files(argv[1], argv[2], block);
    } else if (argc == 5) {
      if (!strcmp(argv[1], "debug")) {
        size_t block = atol(argv[4]);
        calculate_blocked(argv[2], argv[3], strlen(argv[2]), strlen(argv[3]), block);
        return 0;
      }
    } else {
      if (!strcmp(argv[1], "debug")) {
        calculate("", argv[2], 0, strlen(argv[2]));
        return 0;
      }
      return calculate_files(argv[1], argv[2], BUCKET);
    }
  } else if (argc == 2) {
    return calculate_file(argv[1]);
  } else {
    print_usage();
  }
}
