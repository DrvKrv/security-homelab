# Exercise 3: Write the dc01 file yourself

**Goal:** the real test of whether you've learned this - write a VM definition
from scratch, using web-srv as your model.

## Do this

1. Make sure you can explain every line of `web-srv.tf`. If not, go back to it.
2. Open `dc01.tf.todo`. It has the structure and hints but the blanks are yours.
3. Fill it in. dc01 is a **Windows** VM with **no public IP**:
   - the VM block looks like `azurerm_windows_virtual_machine.win_srv` in
     `core.tf` (password via `random_password`, Windows image), but
   - it's count-gated on `var.enable_dc01` with `[0]` indexing and no public IP,
     like `web-srv.tf`.
4. Rename it so Terraform sees it:
   ```bash
   mv dc01.tf.todo dc01.tf
   ```
5. Check your work with the tools, not by peeking:
   ```bash
   terraform fmt      # fixes spacing, and errors on broken syntax
   terraform validate # checks the config makes sense
   terraform plan      # with enable_dc01 = true, see what it would build
   ```
6. Only after you've got a clean `validate`, compare with `answers/dc01.tf`.

## Predict first

- dc01 holds every company account. Write a comment at the top of your file
  answering: should it ever have a public IP, and how will you administer it
  without one?
- You created the VM, but it isn't a domain controller yet. What still has to
  run, and where does that live in the repo? (Look in `lab/stages/3-dc01/`.)

## The lesson

Reading code and writing code are different skills. Anyone can copy a VM block
in seconds - but catching that dc01 must *not* get a public IP, and knowing why, is
the judgment that still matters. That's the part you're practising here.
