#include <iostream>
#include <cstdint>
#include <map>
#include <string>
#include <vector>

using namespace std;

//#define IS_DEBUG

#ifdef IS_DEBUG
#define DEBUG(expr) (expr)
#else
#define DEBUG(expr)
#endif

#define STATE_EXPECT_SPAN 0
#define STATE_TAG_OPEN 1
#define STATE_TAG_NAME 2
#define STATE_EXPECT_ATTRIBUTE 3
#define STATE_EXPECT_DATA 4
#define STATE_EXPECT_CLOSE_TAG 5
#define STATE_EXPECT_ATTRIBUTE_EQUAL_SIGN 6
#define STATE_EXPECT_ATTRIBUTE_OPEN_STRING 7
#define STATE_EXPECT_CLASS 8
#define STATE_READ_CLASS 9
#define STATE_EXPECT_CLOSE_TAG_SLASH 10
#define STATE_EXPECT_CLOSE_TAG_NAME 11
#define STATE_EXPECT_FINAL_TAG_CLOSE 12
#define STATE_EXPECT_STYLE 13
#define STATE_READ_STYLE_NAME 14
#define STATE_EXPECT_STYLE_NAME_COLON 15
#define STATE_EXPECT_STYLE_VALUE 16
#define STATE_READ_STYLE_VALUE 17
#define STATE_READ_STYLE_VALUE_EXPECT_SEMICOLON 18

#define COLOR_STATE_EXPECT_BEGIN 0
#define COLOR_STATE_EXPECT_G 1
#define COLOR_STATE_EXPECT_B 2
#define COLOR_STATE_RGB_EXPECT_PARAN_OPEN 3
#define COLOR_STATE_RGB_EXPECT_RED_1 4
#define COLOR_STATE_RGB_EXPECT_RED_2 5
#define COLOR_STATE_RGB_EXPECT_RED_3 6
#define COLOR_STATE_RGB_EXPECT_RED_COMMA 7
#define COLOR_STATE_RGB_EXPECT_GREEN_1 8
#define COLOR_STATE_RGB_EXPECT_GREEN_2 9
#define COLOR_STATE_RGB_EXPECT_GREEN_3 10
#define COLOR_STATE_RGB_EXPECT_GREEN_COMMA 11
#define COLOR_STATE_RGB_EXPECT_BLUE_1 12
#define COLOR_STATE_RGB_EXPECT_BLUE_2 13
#define COLOR_STATE_RGB_EXPECT_BLUE_3 14
#define COLOR_STATE_RGB_EXPECT_PARAN_CLOSE 15
#define COLOR_STATE_EXPECT_END 16

#define IS_WS(ch) ((ch==' ')||(ch=='\t')||(ch=='\r')||(ch=='\n'))

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

void write_rgb(uint8_t r, uint8_t g, uint8_t b) {
  uint8_t encoded_g = g ^ r;
  uint8_t encoded_b = b ^ g;
  uint32_t encoded_value = r | (encoded_g << 8) | (encoded_b << 16);
  write_size(encoded_value);
}

bool parse_color(string const& value, uint8_t& r, uint8_t& g, uint8_t& b) {
  size_t index = 0;
  r = g = b = 0;
  int state = COLOR_STATE_EXPECT_BEGIN;

  for (size_t index = 0; index < value.length(); index++) {
    char ch = value[index];

    switch (state) {
      case COLOR_STATE_EXPECT_BEGIN:
        if (!IS_WS(ch)) {
          if (ch != 'r' && ch != 'R') {
            cerr << "ERR: incorrect RGB specification for '" << value << "' AT OFFSET " << index << endl;
            return false;
          }
          state = COLOR_STATE_EXPECT_G;
        }
        break;

      case COLOR_STATE_EXPECT_G:
        if (ch != 'g' && ch != 'G') {
            cerr << "ERR: incorrect RGB specification for '" << value << "' AT OFFSET " << index << endl;
            return false;
        }
        state = COLOR_STATE_EXPECT_B;
        break;

      case COLOR_STATE_EXPECT_B:
        if (ch != 'b' && ch != 'B') {
            cerr << "ERR: incorrect RGB specification for '" << value << "' AT OFFSET " << index << endl;
            return false;
        }
        state = COLOR_STATE_RGB_EXPECT_PARAN_OPEN;
        break;

      case COLOR_STATE_RGB_EXPECT_PARAN_OPEN:
        if (!IS_WS(ch)) {
          if (ch != '(') {
            cerr << "ERR: incorrect RGB specification for '" << value << "' AT OFFSET " << index << endl;
            return false;
          }
          state = COLOR_STATE_RGB_EXPECT_RED_1;
        }
        break;

      case COLOR_STATE_RGB_EXPECT_RED_1:
        if (!IS_WS(ch)) {
          if (ch < '0' || ch > '9') {
            cerr << "ERR: incorrect RGB specification for '" << value << "' AT OFFSET " << index << endl;
            return false;
          }
          r = ch - '0';
          state = COLOR_STATE_RGB_EXPECT_RED_2;
        }
        break;

      case COLOR_STATE_RGB_EXPECT_RED_2:
        if (IS_WS(ch)) {
          state = COLOR_STATE_RGB_EXPECT_RED_COMMA;
        } else if (ch == ',') {
          state = COLOR_STATE_RGB_EXPECT_GREEN_1;
        } else if (ch >= '0' && ch <= '9') {
          r = (r * 10) + (ch - '0');
          state = COLOR_STATE_RGB_EXPECT_RED_3;
        } else {
            cerr << "ERR: incorrect RGB specification for '" << value << "' AT OFFSET " << index << endl;
            return false;
        }
        break;

      case COLOR_STATE_RGB_EXPECT_RED_3:
        if (IS_WS(ch)) {
          state = COLOR_STATE_RGB_EXPECT_RED_COMMA;
        } else if (ch == ',') {
          state = COLOR_STATE_RGB_EXPECT_GREEN_1;
        } else if (ch >= '0' && ch <= '9') {
          r = (r * 10) + (ch - '0');
          state = COLOR_STATE_RGB_EXPECT_RED_COMMA;
        } else {
            cerr << "ERR: incorrect RGB specification for '" << value << "' AT OFFSET " << index << endl;
            return false;
        }
        break;

      case COLOR_STATE_RGB_EXPECT_RED_COMMA:
        if (!IS_WS(ch)) {
          if (ch == ',') {
            state = COLOR_STATE_RGB_EXPECT_GREEN_1;
          } else {
            cerr << "ERR: incorrect RGB specification for '" << value << "' AT OFFSET " << index << endl;
            return false;
          }
        }
        break;

      case COLOR_STATE_RGB_EXPECT_GREEN_1:
        if (!IS_WS(ch)) {
          if (ch < '0' || ch > '9') {
            cerr << "ERR: incorrect RGB specification for '" << value << "' AT OFFSET " << index << endl;
            return false;
          }
          g = ch - '0';
          state = COLOR_STATE_RGB_EXPECT_GREEN_2;
        }
        break;

      case COLOR_STATE_RGB_EXPECT_GREEN_2:
        if (IS_WS(ch)) {
          state = COLOR_STATE_RGB_EXPECT_GREEN_COMMA;
        } else if (ch == ',') {
          state = COLOR_STATE_RGB_EXPECT_BLUE_1;
        } else if (ch >= '0' && ch <= '9') {
          g = (g * 10) + (ch - '0');
          state = COLOR_STATE_RGB_EXPECT_GREEN_3;
        } else {
            cerr << "ERR: incorrect RGB specification for '" << value << "' AT OFFSET " << index << endl;
            return false;
        }
        break;

      case COLOR_STATE_RGB_EXPECT_GREEN_3:
        if (IS_WS(ch)) {
          state = COLOR_STATE_RGB_EXPECT_GREEN_COMMA;
        } else if (ch == ',') {
          state = COLOR_STATE_RGB_EXPECT_BLUE_1;
        } else if (ch >= '0' && ch <= '9') {
          g = (g * 10) + (ch - '0');
          state = COLOR_STATE_RGB_EXPECT_GREEN_COMMA;
        } else {
            cerr << "ERR: incorrect RGB specification for '" << value << "' AT OFFSET " << index << endl;
            return false;
        }
        break;

      case COLOR_STATE_RGB_EXPECT_GREEN_COMMA:
        if (!IS_WS(ch)) {
          if (ch == ',') {
            state = COLOR_STATE_RGB_EXPECT_BLUE_1;
          } else {
            cerr << "ERR: incorrect RGB specification for '" << value << "' AT OFFSET " << index << endl;
            return false;
          }
        }
        break;

      case COLOR_STATE_RGB_EXPECT_BLUE_1:
        if (!IS_WS(ch)) {
          if (ch < '0' || ch > '9') {
            cerr << "ERR: incorrect RGB specification for '" << value << "' AT OFFSET " << index << endl;
            return false;
          }
          b = ch - '0';
          state = COLOR_STATE_RGB_EXPECT_BLUE_2;
        }
        break;

      case COLOR_STATE_RGB_EXPECT_BLUE_2:
        if (IS_WS(ch)) {
          state = COLOR_STATE_RGB_EXPECT_PARAN_CLOSE;
        } else if (ch == ')') {
          state = COLOR_STATE_EXPECT_END;
        } else if (ch >= '0' && ch <= '9') {
          b = (b * 10) + (ch - '0');
          state = COLOR_STATE_RGB_EXPECT_BLUE_3;
        } else {
            cerr << "ERR: incorrect RGB specification for '" << value << "' AT OFFSET " << index << endl;
            return false;
        }
        break;

      case COLOR_STATE_RGB_EXPECT_BLUE_3:
        if (IS_WS(ch)) {
          state = COLOR_STATE_RGB_EXPECT_PARAN_CLOSE;
        } else if (ch == ')') {
          state = COLOR_STATE_EXPECT_END;
        } else if (ch >= '0' && ch <= '9') {
          b = (b * 10) + (ch - '0');
          state = COLOR_STATE_RGB_EXPECT_PARAN_CLOSE;
        } else {
            cerr << "ERR: incorrect RGB specification for '" << value << "' AT OFFSET " << index << endl;
            return false;
        }
        break;

      case COLOR_STATE_RGB_EXPECT_PARAN_CLOSE:
        if (!IS_WS(ch)) {
          if (ch == ')') {
            state = COLOR_STATE_EXPECT_END;
          } else {
            cerr << "ERR: incorrect RGB specification for '" << value << "' AT OFFSET " << index << endl;
            return false;
          }
        }
        break;

      case COLOR_STATE_EXPECT_END:
        if (!IS_WS(ch)) {
            cerr << "ERR: incorrect RGB specification for '" << value << "' AT OFFSET " << index << endl;
            return false;
        }
        break;

      default:
        cerr << "ERR: incorrect state: " << state << " while parsing color" << endl;
        break;
    }
  }

  return true;
}

int main(int argc, char* argv[]) {
  map<string, uint16_t> flag_mappings;
  map<string, uint8_t> color_mappings;

  flag_mappings["reset"] = 1u<<0;
  flag_mappings["bg-reset"] = 1u<<1;
  flag_mappings["bold"] = 1u<<2;
  flag_mappings["italic"] = 1u<<3;
  const uint16_t FLAG_RGB_FC = 1u<<4;
  const uint16_t FLAG_RGB_BC = 1u<<5;
  flag_mappings["highlighted"] = 1u<<6;
  flag_mappings["underline"] = 1u<<7;
  flag_mappings["crossed-out"] = 1u<<8;
  flag_mappings["blink"] = 1u<<9;

  color_mappings["white"] = 0u;
  color_mappings["red"] = 1u;
  color_mappings["green"] = 2u;
  color_mappings["yellow"] = 3u;
  color_mappings["blue"] = 4u;
  color_mappings["purple"] = 5u;
  color_mappings["cyan"] = 6u;
  color_mappings["dimgray"] = 7u;
  color_mappings["bg-black"] = 0u;
  color_mappings["bg-red"] = 1u<<3;
  color_mappings["bg-green"] = 2u<<3;
  color_mappings["bg-yellow"] = 3u<<3;
  color_mappings["bg-blue"] = 4u<<3;
  color_mappings["bg-purple"] = 5u<<3;
  color_mappings["bg-cyan"] = 6u<<3;
  color_mappings["bg-white"] = 7u<<3;
  color_mappings["inverted"] = 1u<<6;
  color_mappings["bg-inverted"] = 1u<<7;

  uint8_t fc_r=0, fc_g=0, fc_b=0;
  uint8_t bc_r=0, bc_g=0, bc_b=0;
  bool fc_rgb = false;
  bool bc_rgb = false;

  char ch;
  int state = STATE_EXPECT_SPAN;
  vector<char> buffer;
  uint16_t flags = 0;
  uint8_t colors = 0;

  string attribute_name;
  string style_name;

  int index = -1;
  int line = 1;
  while (cin.get(ch)) {
    if (ch == '\n') {
      line++;
      index = -1;
    }
    if (ch != '\r') {
      index++;
    }

    switch (state) {
      case STATE_EXPECT_SPAN:
        if (ch == '<') {
          state = STATE_TAG_OPEN;
        }
        break;

      case STATE_TAG_OPEN:
        if (!IS_WS(ch)) {
          if (ch == '>' || ch == '/') {
            cerr << "ERR: EMPTY TAG <> READ AT " << index << endl;
            return -1;
          } else {
            state = STATE_TAG_NAME;
            buffer.push_back(ch);
          }
        }
        break;

      case STATE_TAG_NAME:
        if (!IS_WS(ch)) {
          if (ch == '>' || ch == '/') {
            string tag_name = string(buffer.begin(), buffer.end());
            if (tag_name != "span") {
              cerr << "ERR: UNKNOWN TAG <" << tag_name << endl;
              return -1;
            }
            buffer.clear();

            if (ch == '>') {
              state = STATE_EXPECT_DATA;
            } else {
              state = STATE_EXPECT_CLOSE_TAG;
            }
          } else {
            buffer.push_back(ch);
          }
        } else {
          string tag_name = string(buffer.begin(), buffer.end());
          if (tag_name != "span") {
            cerr << "ERR: UNKNOWN TAG <" << tag_name << endl;
            return -1;
          }
          buffer.clear();
          state = STATE_EXPECT_ATTRIBUTE;
        }
        break;

      case STATE_EXPECT_CLOSE_TAG:
        if (ch == '>') {
          state = STATE_EXPECT_DATA;
        } else if (ch != ' ' && ch != '\t') {
          cerr << "ERR: INCORRECT HTML AT " << index << endl;
          return 1;
        }
        break;

      case STATE_EXPECT_ATTRIBUTE:
        if (!IS_WS(ch)) {
          if (ch == '>') {
            DEBUG(cerr << "INFO: start reading data AT " << line << ":" << index << endl);
            state = STATE_EXPECT_DATA;
          } else if (ch == '/') {
            state = STATE_EXPECT_CLOSE_TAG;
          } else {
            buffer.push_back(ch);
            state = STATE_EXPECT_ATTRIBUTE_EQUAL_SIGN;
          }
        }
        break;

      case STATE_EXPECT_ATTRIBUTE_EQUAL_SIGN:
        if (ch != '=') {
          buffer.push_back(ch);
        } else {
          attribute_name = string(buffer.begin(), buffer.end());
          if (attribute_name != "class" && attribute_name != "style") {
            cerr << "ERR: UNKNOWN ATTRIBUTE " << attribute_name << " AT " << index << endl;
            return -1;
          }
          buffer.clear();
          state = STATE_EXPECT_ATTRIBUTE_OPEN_STRING;
        }
        break;

      case STATE_EXPECT_ATTRIBUTE_OPEN_STRING:
        if (ch != '"') {
          cerr << "ERR: UNKNOWN CLASS SPECIFICATION AT " << index << endl;
          return -1;
        }
        if (attribute_name == "class") {
          state = STATE_EXPECT_CLASS;
        } else if (attribute_name == "style") {
          state = STATE_EXPECT_STYLE;
        } else {
          cerr << "ERR: UNKNOWN ATTRIBUTE " << attribute_name << " AT " << line << ":" << index << endl;
          return -1;
        }
        attribute_name = "";
        break;

      case STATE_EXPECT_STYLE:
        if (!IS_WS(ch)) {
          if (ch == '"') {
            state = STATE_EXPECT_ATTRIBUTE;
          } else if (ch != ';') {
            buffer.push_back(ch);
            state = STATE_READ_STYLE_NAME;
          }
        }
        break;

      case STATE_READ_STYLE_NAME:
        if (IS_WS(ch) || ch == ':') {
          style_name = string(buffer.begin(), buffer.end());
          buffer.clear();
          if (style_name != "color" && style_name != "background-color") {
            // this is probably sign of incorrect HTML generated by `aha`
            map<string, uint8_t>::iterator jt = color_mappings.find(style_name);
            if (jt == color_mappings.end()) {
              cerr << "ERR: UNKNOWN STYLE " << style_name << " AT " << line << ":" << index << endl;
              return -1;
            }

            colors = colors | jt->second;
            state = STATE_EXPECT_STYLE;
          } else {
            if (IS_WS(ch)) {
              state = STATE_EXPECT_STYLE_NAME_COLON;
            } else {
              state = STATE_EXPECT_STYLE_VALUE;
            }
          }
        } else {
          buffer.push_back(ch);
        }
        break;

      case STATE_EXPECT_STYLE_NAME_COLON:
        if (!IS_WS(ch)) {
          if (ch == ':') {
            state = STATE_EXPECT_STYLE_VALUE;
          } else {
            cerr << "ERR: UNKNOWN STYLE SPECIFICAION FOR '" << style_name << "' AT " << line << ":" << index << endl;
            return -1;
          }
        }
        break;

      case STATE_EXPECT_STYLE_VALUE:
        if (!IS_WS(ch)) {
          if (ch == ';' || ch == '"') {
            cerr << "ERR: UNKNOWN STYLE SPECIFICATION FOR '" << style_name << "' AT " << line << ":" << index << endl;
            return -1;
          } else {
            buffer.push_back(ch);
            state = STATE_READ_STYLE_VALUE;
          }
        }
        break;

      case STATE_READ_STYLE_VALUE:
        if (ch == ';' || ch == '"') {
          string style_value = string(buffer.begin(), buffer.end());
          buffer.clear();
          DEBUG(cerr << "INFO: READ '" << style_value << "' FOR " << style_name << " AT " << line << ":" << index << endl);

          if (style_name == "color") {
            if (!parse_color(style_value, fc_r, fc_g, fc_b)) {
              cerr << "ERR: CAN NOT PARSE '" << style_value << "' style value for style '" << style_name << "' AT " << line << ":" << index << endl;
              return -1;
            }
            fc_rgb = true;
            flags = flags | FLAG_RGB_FC;
            DEBUG(cerr << "INFO: READ " << (int)fc_r << "," << (int)fc_g << "," << (int)fc_b << " FOR " << style_name << " FROM " << style_value << endl);
          } else if (style_name == "background-color") {
            if (!parse_color(style_value, bc_r, bc_g, bc_b)) {
              cerr << "ERR: CAN NOT PARSE '" << style_value << "' style value for style '" << style_name << "' AT " << line << ":" << index << endl;
              return -1;
            }
            bc_rgb = true;
            flags = flags | FLAG_RGB_BC;
            DEBUG(cerr << "INFO: READ " << (int)bc_r << "," << (int)bc_g << "," << (int)bc_b << " FOR " << style_name << " FROM " << style_value << endl);
          }

          if (ch == ';') {
            state = STATE_EXPECT_STYLE;
          } else {
            state = STATE_EXPECT_ATTRIBUTE;
          }
        } else {
          buffer.push_back(ch);
        }
        break;

      case STATE_READ_STYLE_VALUE_EXPECT_SEMICOLON:
        if (ch == ';') {
          state = STATE_EXPECT_STYLE;
        } else if (ch == '"') {
          state = STATE_EXPECT_ATTRIBUTE;
        } else if (!IS_WS(ch)) {
          cerr << "ERR: UNKNOWN STYLE SPECIFICATION FOR '" << style_name << "' AT " << line << ":" << index << endl;
          return -1;
        }
        break;

      case STATE_EXPECT_CLASS:
        if (!IS_WS(ch)) {
          if (ch == '"') {
            state = STATE_EXPECT_ATTRIBUTE;
          } else {
            buffer.push_back(ch);
            state = STATE_READ_CLASS;
          }
        }
        break;

      case STATE_READ_CLASS:
        if (IS_WS(ch) || ch == '"') {
          string class_name = string(buffer.begin(), buffer.end());
          map<string, uint16_t>::iterator it = flag_mappings.find(class_name);
          if (it == flag_mappings.end()) {
            map<string, uint8_t>::iterator jt = color_mappings.find(class_name);
            if (jt == color_mappings.end()) {
              cerr << "ERR: UNSUPPORTED CLASS " << class_name << " AT " << line << ":" << index << endl;
              return -1;
            } else {
              colors = colors | jt->second;
            }
          } else {
            flags = flags | it->second;
          }
          DEBUG(cerr << "INFO: APPLYING CLASS " << class_name << " AT " << line << ":" << index << " AND FLAGS IS NOW: " << (int)flags << " AND COLORS IS NOW: " << (int)colors << endl);
          buffer.clear();
          if (ch == '"') {
            state = STATE_EXPECT_ATTRIBUTE;
          } else {
            state = STATE_EXPECT_CLASS;
          }
        } else {
          buffer.push_back(ch);
        }
        break;

      case STATE_EXPECT_DATA:
        if (ch != '<') {
          buffer.push_back(ch);
        } else {
          if (buffer.size() > 0) {
            write_size(flags);

            if (!fc_rgb || !bc_rgb) {
              cout.write((char*)&colors, sizeof(colors));
            }
            if (fc_rgb) {
              write_rgb(fc_r, fc_g, fc_b);
            }
            if (bc_rgb) {
              write_rgb(bc_r, bc_g, bc_b);
            }
            write_size(buffer.size());
            cout.write(buffer.data(), buffer.size());
          }
          DEBUG(cerr << "INFO: READ " << buffer.size() << " BYTES WITH FLAG " << (int)flags << " AND COLOR " << (int)colors << " NOW AT " << line << ":" << index << endl);
          flags = 0;
          colors = 0;
          fc_r = fc_g = fc_b = 0;
          bc_r = bc_g = bc_b = 0;
          fc_rgb = bc_rgb = false;
          buffer.clear();
          state = STATE_EXPECT_CLOSE_TAG_SLASH;
        }
        break;

      case STATE_EXPECT_CLOSE_TAG_SLASH:
        if (ch == '/') {
          state = STATE_EXPECT_CLOSE_TAG_NAME;
        } else if (ch != ' ' && ch != '\t') {
          cerr << "ERR: INCORRECT HTML AT " << index << endl;
          return -1;
        }
        break;

      case STATE_EXPECT_CLOSE_TAG_NAME:
        if (ch != '>' && !IS_WS(ch)) {
          buffer.push_back(ch);
        } else {
          string tag_name = string(buffer.begin(), buffer.end());
          if (tag_name != "span") {
            cerr << "ERR: INCORRECT CLOSING TAG NAME " << tag_name << " AT " << index << endl;
            return -1;
          }
          buffer.clear();

          if (ch == '>') {
            state = STATE_EXPECT_SPAN;
          } else {
            state = STATE_EXPECT_FINAL_TAG_CLOSE;
          }
        }
        break;

      case STATE_EXPECT_FINAL_TAG_CLOSE:
        if (ch == '>') {
          state = STATE_EXPECT_SPAN;
        } else if (!IS_WS(ch)) {
          cerr << "ERR: INCORRECT HTML(STATE_EXPECT_FINAL_TAG_CLOSE) AT " << index << " WITH CH='" << ch << "'" << endl;
          return -1;
        }
        break;

      default:
        cerr << "ERR: UNHANDLED STATE " << state << endl;
        return -1;
        break;
    }
  }

  if (state != STATE_EXPECT_SPAN) {
    cerr << "ERR: INCORRECT FINAL STATE " << state << endl;
    return -1;
  }

  return 0;
}
