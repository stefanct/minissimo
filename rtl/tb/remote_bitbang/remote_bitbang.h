// See LICENSE.Berkeley for license details.

#ifndef REMOTE_BITBANG_H
#define REMOTE_BITBANG_H

#include <stdint.h>
#include <sys/types.h>

#define VERBOSE 0


// Create a new server, listening for connections from localhost on the given
// port.
int rbs_init(uint16_t port);

// Do a bit of work.
void rbs_tick(unsigned char *jtag_tck, unsigned char *jtag_tms,
              unsigned char *jtag_tdi, unsigned char *jtag_trstn,
              unsigned char jtag_tdo);

unsigned char rbs_done();

int rbs_exit_code();

// Check for a client connecting, and accept if there is one.
void rbs_accept();
// Execute any commands the client has for us.
// But we only execute 1 because we need time for the
// simulation to run.
void rbs_execute_command();

// Reset. Currently does nothing.
void rbs_reset();

void rbs_set_pins(char _tck, char _tms, char _tdi);

#endif
