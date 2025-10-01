# 🕵️ Recon Course

- This project will demonstrate how to use the tools in ProjectDiscovery to efficiently investigate bug bounties.
- This tool is automated, it doesn't mean it's the most efficient, you should do it manually to get better results, but this automation is just my workflow.
## 📦 Install Tools

```bash

chmod +x setup.sh
sudo ./setup.sh

```

## 📖 Text-based help messages
```bash

chmod +x hc_tools_txt.sh
./hc_tools_txt.sh

```
## 💻 Request CLI help
```bash

chmod +x hc_tools.sh
./hc_tools.sh

```
## 🚀 Initiation of deployment and reconnaissance
```bash

chmod +x recon.sh
./recon.sh 

```

## 💻 A subdomain takeover detection tool for cool kids 
```bash

chmod +x Subdominator
./Subdominator -h

Description:
  A subdomain takeover detection tool for cool kids

Usage:
  Subdominator [options]

Options:
  -d, --domain <domain>                  A single domain to check
  DomainsFile, -l, --list <DomainsFile>  A list of domains to check (line delimited)
  OutputFile, -o, --output <OutputFile>  Output subdomains to a file
  -t, --threads <threads>                Number of domains to check at once [default: 50]
  -v, --verbose                          Print extra information
  -q, --quiet                            Quiet mode: Only print found results
  CsvHeading, -c, --csv <CsvHeading>     Heading or column index to parse for CSV file. Forces -l to read as CSV instead of line-delimited
  -eu, --exclude-unlikely                Exclude unlikely (edge-case) fingerprints
  --validate                             Validate the takeovers are exploitable (where possible)
  --version                              Show version information
  -?, -h, --help                         Show help and usage information


```
## 📌 Notes

- Ensure all required dependencies are installed.

- Recommended to run on Linux / WSL for best results.

- Learn more from ProjectDiscovery docs: https://projectdiscovery.io
