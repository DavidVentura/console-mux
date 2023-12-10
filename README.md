# console-mux

This project allows propagating the values of any pin defined as `input` onto any (0-n) of the pins defined as `output`.

My use-case is to allow direct connectivity to any of the SBC in my lab, so that I can flash and debug them without needing
to rewire their UART connections.

The project is built using the Tang Nano 1K FPGA board and can be thought of as a simplified console server.


Something like (no connection):
```
            _________
           |         |
           |         |--> SBC1 RX
           |         |--> SBC1 TX
 PC RX  <--|         |--> SBC2 RX
 PC TX  <--|         |--> SBC2 TX
           |         |--> SBC3 RX
           |         |--> SBC3 TX
           |_________|
```

And after wiring PC to SBC1
```
            __________
           |          |
           |     ╭────|--> SBC1 TX
           |     │ ╭──|--> SBC1 RX
 PC RX  <--|─────╯ │  |--> SBC2 TX
 PC TX  <--|───────╯  |--> SBC2 RX
           |          |--> SBC3 TX
           |          |--> SBC3 RX
           |__________|
```

# Setup

Requires [oss-cad-suite-build](https://github.com/YosysHQ/oss-cad-suite-build) to be in $PATH.

Run `make test` to run the tests and `make build` to generate the bitstream. Flash it with `make flash`.
