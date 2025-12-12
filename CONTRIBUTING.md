# Contributing Guidelines

Thank you for considering contributing to this project!

---

## How to Contribute

### Reporting Issues

If you encounter problems:

1. **Check existing issues** - Your issue may already be reported
2. **Run diagnostics** - Include output of `scripts/diagnostics.sh`
3. **Provide details:**
   - MacBook model (run: `cat /sys/class/dmi/id/product_name`)
   - Kernel version (run: `uname -r`)
   - Zorin/Ubuntu version (run: `lsb_release -a`)
   - Steps to reproduce
   - Error messages or logs

### Suggesting Enhancements

For feature requests:

1. Explain the use case
2. Describe expected behavior
3. Note if it works on other T2 MacBook models
4. Provide examples or references

### Pull Requests

We welcome improvements! To contribute code:

1. **Fork the repository**
2. **Create a feature branch:**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make your changes:**
   - Follow existing code style
   - Test on actual T2 hardware if possible
   - Update documentation if needed

4. **Test your changes:**
   - Run shellcheck on scripts: `shellcheck scripts/*.sh`
   - Test installation on fresh Zorin OS if possible
   - Verify all hardware still works

5. **Commit with clear messages:**
   ```bash
   git commit -m "Add: Brief description of changes"
   ```

6. **Push and create PR:**
   ```bash
   git push origin feature/your-feature-name
   ```
   Then open a Pull Request on GitHub

---

## Code Style

### Shell Scripts

- Use `#!/bin/bash` shebang
- Use `set -e` for error handling
- Add comments for complex sections
- Use meaningful variable names
- Quote variables: `"$VAR"` not `$VAR`
- Check exit codes for critical commands

**Example:**
```bash
#!/bin/bash
set -e

# Install required package
if ! command -v tool &> /dev/null; then
    sudo apt-get install -y tool
fi

# Do something
result=$(command --option)
echo "Result: $result"
```

### Documentation

- Use Markdown format
- Include code blocks with syntax highlighting
- Provide examples
- Keep line length reasonable (~80-100 chars)
- Use proper headings hierarchy

---

## Testing

Before submitting changes:

### Manual Testing

1. **Test on fresh install** (if possible):
   ```bash
   sudo bash scripts/master_install.sh
   ```

2. **Verify all hardware works:**
   ```bash
   bash scripts/diagnostics.sh
   ```

3. **Test individual scripts:**
   ```bash
   sudo bash scripts/01_install_wifi_bluetooth.sh
   # Test WiFi
   sudo bash scripts/02_install_t2_kernel.sh
   # Reboot and test
   ```

### Static Analysis

```bash
# Install shellcheck
sudo apt install shellcheck

# Check all scripts
find scripts -name "*.sh" -exec shellcheck {} \;
```

---

## Documentation Updates

When adding features:

- Update `README.md` if it affects quick start
- Update `docs/MANUAL_INSTALL.md` with detailed steps
- Update `docs/TROUBLESHOOTING.md` for common issues
- Update `docs/HARDWARE_REFERENCE.md` for hardware changes

---

## Adding Support for New Models

To add support for other T2 MacBooks:

1. **Test on the new model**
2. **Document differences:**
   - WiFi/Bluetooth firmware files
   - Kernel parameters needed
   - Hardware quirks

3. **Update scripts:**
   - Add model detection
   - Add conditional logic if needed

4. **Update documentation:**
   - Add to supported models list
   - Document any model-specific steps

---

## Commit Message Guidelines

Use conventional commit format:

```
Type: Short description

Longer description if needed.

- Detail 1
- Detail 2
```

**Types:**
- `Add:` New feature or script
- `Fix:` Bug fix
- `Update:` Update existing feature
- `Docs:` Documentation only
- `Refactor:` Code restructuring
- `Test:` Add or update tests

**Examples:**
```
Add: Support for MacBookPro16,1

- Add WiFi firmware for BCM4364
- Update kernel parameters
- Test on MacBookPro16,1 hardware

Fix: Microphone not detected after suspend

- Restart PipeWire after resume
- Update UCM configuration
- Tested on MacBookPro15,4

Docs: Add troubleshooting for kernel boot issues

- Document GRUB menu access on Mac
- Add steps to manually select kernel
- Include recovery instructions
```

---

## Code of Conduct

- Be respectful and constructive
- Help others learn
- Accept feedback gracefully
- Focus on the problem, not the person

---

## Questions?

- Open an issue for questions
- Tag with `question` label
- Check existing discussions first

---

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

**Thank you for contributing!** 🎉
