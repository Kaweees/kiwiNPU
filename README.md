<!-- PROJECT SHIELDS -->
<!--
*** I'm using markdown "reference style" links for readability.
*** Reference links are enclosed in brackets [ ] instead of parentheses ( ).
*** See the bottom of this document for the declaration of the reference variables
*** for contributors-url, forks-url, etc. This is an optional, concise syntax you may use.
*** https://www.markdownguide.org/basic-syntax/#reference-style-links
-->
<div align="left">

[![Contributors][contributors-shield]][contributors-url]
[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]

</div>

<a href="https://github.com/Kaweees/kiwiNPU">
  <img alt="SystemVerilog Logo" src="assets/img/systemverilog.png" align="right" width="150">
</a>

<div align="left">
  <h1><em><a href="https://kaweees.github.io/kiwiNPU">~kiwiNPU</a></em></h1>
</div>

<!-- ABOUT THE PROJECT -->

A Neural Processing Unit (NPU) accelerator ASIC designed for deep learning inference written in SystemVerilog.

### Built With

[![SystemVerilog][SystemVerilog-shield]][SystemVerilog-url]
[![GNU Make][GNU-Make-shield]][GNU-Make-url]
[![NixOS][NixOS-shield]][NixOS-url]
[![GitHub Actions][github-actions-shield]][github-actions-url]

<!-- PROJECT PREVIEW -->
## Preview

<p align="center">
  <img src="assets/img/demo.webm"
  width = "80%"
  alt = "Video demonstration"
  />
</p>

<!-- GETTING STARTED -->

## Getting Started

### Prerequisites

Before attempting to build this project, make sure you have [Verilator](https://www.veripool.org/verilator/) and [Nix](https://nixos.org/download.html) installed on your machine.

### Installation

To get a local copy of the project up and running on your machine, follow these simple steps:

1. Clone the project repository

   ```sh
   git clone https://github.com/Kaweees/kiwiNPU.git
   cd kiwiNPU
   ```

2. Install the project dependencies

   ```sh
   nix develop
   curl -LsSf https://astral.sh/uv/install.sh | sh
   ```

3. Run the project

   ```sh
   uv run ./scripts/dotproduct_generate.py
   uv run ./scripts/perceptron_generate.py
   make
   ```

<!-- PROJECT FILE STRUCTURE -->

## Project Structure

```sh
.kiwiNPU/
├── .github/                       - GitHub Actions CI/CD workflows
├── include/                       - Header files
├── rtl/                           - RTL source files
├── tb/                            - Testbench files
├── Makefile                       - Makefile build script
├── LICENSE                        - Project license
└── README.md                      - You are here
```

## License

The source code for this project is distributed under the terms of the GNU General Public License v3.0, as I firmly believe that collaborating on free and open-source software fosters innovations that mutually and equitably beneficial to both collaborators and users alike. See [`LICENSE`](./LICENSE) for details and more information.

<!-- MARKDOWN LINKS & IMAGES -->
<!-- https://www.markdownguide.org/basic-syntax/#reference-style-links -->

[contributors-shield]: https://img.shields.io/github/contributors/Kaweees/kiwiNPU.svg?style=for-the-badge
[contributors-url]: https://github.com/Kaweees/kiwiNPU/graphs/contributors
[forks-shield]: https://img.shields.io/github/forks/Kaweees/kiwiNPU.svg?style=for-the-badge
[forks-url]: https://github.com/Kaweees/kiwiNPU/network/members
[stars-shield]: https://img.shields.io/github/stars/Kaweees/kiwiNPU.svg?style=for-the-badge
[stars-url]: https://github.com/Kaweees/kiwiNPU/stargazers

<!-- MARKDOWN SHIELD BAGDES & LINKS -->
<!-- https://github.com/Ileriayo/markdown-badges -->

[SystemVerilog-shield]: https://img.shields.io/badge/SystemVerilog-%f7a41d.svg?style=for-the-badge&logo=SystemVerilog&logoColor=f7a41d&labelColor=222222&color=f7a41d
[SystemVerilog-url]: https://www.systemverilog.org/
[GNU-Make-shield]: https://img.shields.io/badge/GNU%20Make-%23008080.svg?style=for-the-badge&logo=gnu&logoColor=A42E2B&labelColor=222222&color=A42E2B
[GNU-Make-url]: https://www.gnu.org/software/make/
[NixOS-shield]: https://img.shields.io/badge/nix%20flakes-%23008080.svg?style=for-the-badge&logo=NixOS&logoColor=5277C3&labelColor=222222&color=5277C3
[NixOS-url]: https://nixos.org/
[github-actions-shield]: https://img.shields.io/badge/github%20actions-%232671E5.svg?style=for-the-badge&logo=githubactions&logoColor=2671E5&labelColor=222222&color=2671E5
[github-actions-url]: https://github.com/features/actions
