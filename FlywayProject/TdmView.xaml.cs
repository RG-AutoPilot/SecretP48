using System;
using System.Diagnostics;
using System.IO;
using System.IO.Compression;
using System.Net;
using System.Windows;
using System.Windows.Controls;
using static System.Windows.Forms.VisualStyles.VisualStyleElement.Window;
using WinForms = System.Windows.Forms;

namespace FlywayProject
{
    public partial class TdmView : UserControl
    {
        private string stepsFolder;
        private string configFolder;
        private string subsetFolder;
        private string maskingFolder;
        private string modulePath;

        public TdmView()
        {
            InitializeComponent();
        }

        private void InitializePathsFromRoot(string root)
        {
            stepsFolder = Path.Combine(root, "Steps", "Windows");
            configFolder = Path.Combine(root, "Config_Files");
            subsetFolder = Path.Combine(root, "Setup_Files", "Data_Treatments_Options_Files");
            maskingFolder = subsetFolder;
            modulePath = Path.Combine(root, "Setup_Files", "helper-functions.psm1");

            LoadComboBox(ConfigFileComboBox, configFolder, "*.conf");
            LoadComboBox(SubsetOptionsComboBox, subsetFolder, "*.json");
            LoadComboBox(MaskingOptionsComboBox, maskingFolder, "*.json");
        }

        private void LoadComboBox(ComboBox combo, string folder, string filter)
        {
            combo.Items.Clear();
            if (!Directory.Exists(folder)) return;
            foreach (var file in Directory.GetFiles(folder, filter))
                combo.Items.Add(Path.GetFileName(file));
            if (combo.Items.Count > 0) combo.SelectedIndex = 0;
        }

        private string GetSqlArgs()
        {
            var instance = SqlInstanceTextBox.Text.Trim();
            var winAuth = WindowsAuthCheckBox.IsChecked ?? true;
            var encrypt = EncryptConnectionCheckBox.IsChecked ?? true;
            var trust = TrustCertCheckBox.IsChecked ?? true;

            var repoLocation = TdmRootTextBox.Text.Trim();

            var args = $"-sqlInstance \"{instance}\" -winAuth:{winAuth.ToString().ToLower()} -encryptConnection:{encrypt.ToString().ToLower()} -trustCert:{trust.ToString().ToLower()}";

            if (!winAuth)
            {
                args += $" -username \"{UsernameTextBox.Text.Trim()}\" -password \"{PasswordBox.Password.Trim()}\"";
            }

            return args;
        }

        private void RunStep(string scriptName, string extraArgs = "")
        {
            if (string.IsNullOrEmpty(stepsFolder))
            {
                MessageBox.Show("Please select a valid TDM-Autopilot folder.", "Missing Paths", MessageBoxButton.OK, MessageBoxImage.Warning);
                return;
            }

            string scriptPath = Path.Combine(stepsFolder, scriptName);

            if (!File.Exists(scriptPath))
            {
                MessageBox.Show($"Script not found:\n{scriptPath}", "Error", MessageBoxButton.OK, MessageBoxImage.Error);
                return;
            }

            string args = $"{GetSqlArgs()} {extraArgs}".Trim();

            try
            {
                var psi = new ProcessStartInfo
                {
                    FileName = "pwsh.exe",
                    Arguments = $"-NoExit -ExecutionPolicy Bypass -File \"{scriptPath}\" {args}",
                    UseShellExecute = true,
                    WorkingDirectory = Path.GetDirectoryName(scriptPath)
                };

                Process.Start(psi);
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Failed to run script:\n{ex.Message}", "Error", MessageBoxButton.OK, MessageBoxImage.Error);
            }
        }


        private void OnBrowseTdmRootClicked(object sender, RoutedEventArgs e)
        {
            var dialog = new WinForms.FolderBrowserDialog
            {
                Description = "Select your TDM-Autopilot folder"
            };

            if (dialog.ShowDialog() == WinForms.DialogResult.OK)
            {
                TdmRootTextBox.Text = dialog.SelectedPath;
                InitializePathsFromRoot(dialog.SelectedPath);
            }
        }

        private void OnTestConnectionClicked(object sender, RoutedEventArgs e)
        {
            RunStep("03a_Create-ConnectionStrings.ps1");
        }

        private void OnCreateDatabasesClicked(object sender, RoutedEventArgs e)
        {
            string repoLocation = TdmRootTextBox.Text.Trim();
            RunStep("03b_Provision-Databases.ps1", $"-repoLocation \"{repoLocation}\"");
        }


        private void OnRunSubsetClicked(object sender, RoutedEventArgs e)
        {
            if (!(SubsetOptionsComboBox.SelectedItem is string file) || string.IsNullOrWhiteSpace(file))      
            {
                MessageBox.Show("Please select a valid subset options file.", "Missing Input", MessageBoxButton.OK, MessageBoxImage.Warning);
                return;
            }

            string path = Path.Combine(subsetFolder, file);
            if (!File.Exists(path))
            {
                MessageBox.Show($"Subset options file not found:\n{path}", "Error", MessageBoxButton.OK, MessageBoxImage.Error);
                return;
            }

            string source = SourceDbTextBox.Text.Trim();
            string target = TargetDbTextBox.Text.Trim();
            string server = SqlInstanceTextBox.Text.Trim();

            bool encrypt = EncryptConnectionCheckBox.IsChecked ?? true;
            bool trustCert = TrustCertCheckBox.IsChecked ?? true;

            string encryptionArgs = $"Encrypt={encrypt.ToString().ToLower()};TrustServerCertificate={trustCert.ToString().ToLower()}";

            string sourceConnectionString = $"\"Server={server};Database={source};Integrated Security=true;{encryptionArgs};\"";
            string targetConnectionString = $"\"Server={server};Database={target};Integrated Security=true;{encryptionArgs};\"";

            string extraArgs =
                $"-subsetterOptionsFile \"{path}\" " +
                $"-sourceDb \"{source}\" -targetDb \"{target}\" " +
                $"-sourceConnectionString {sourceConnectionString} " +
                $"-targetConnectionString {targetConnectionString}";

            RunStep("04_Subset-Data.ps1", extraArgs);
        }





        private void OnGenerateClassificationClicked(object sender, RoutedEventArgs e)
        {
            RunStep("05_Classify-Data.ps1");
        }

        private void OnGenerateMaskingFileClicked(object sender, RoutedEventArgs e)
        {
            RunStep("06_Map-Data.ps1");
        }

        private void OnRunMaskingClicked(object sender, RoutedEventArgs e)
        {
            if (MaskingOptionsComboBox.SelectedItem is string file)
            {
                string path = Path.Combine(maskingFolder, file);
                RunStep("07_Mask-Data.ps1", $"-maskingFile \"{path}\"");
            }
        }

        private void OnInstallDbatoolsClicked(object sender, RoutedEventArgs e)
        {
            try
            {
                var script = "if (-not (Get-Command Set-DbatoolsConfig -ErrorAction SilentlyContinue)) { " +
                             "Install-Module dbatools -Scope CurrentUser -Force } " +
                             "else { Write-Host 'dbatools already installed.' }";

                Process.Start(new ProcessStartInfo
                {
                    FileName = "powershell.exe",
                    Arguments = $"-NoExit -ExecutionPolicy Bypass -Command \"{script}\"",
                    UseShellExecute = true
                });
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Failed to install dbatools: {ex.Message}");
            }
        }

        private void OnInstallTdmClisClicked(object sender, RoutedEventArgs e)
        {
            string downloadUrl = "https://download.red-gate.com/tdm/latest.zip"; // Update to actual Redgate URL
            string tempZip = Path.Combine(Path.GetTempPath(), "tdmcli.zip");
            string targetPath = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.UserProfile), "RedgateTDM");

            try
            {
                using (var client = new WebClient())
                {
                    client.DownloadFile(downloadUrl, tempZip);
                }

                if (Directory.Exists(targetPath))
                    Directory.Delete(targetPath, true);

                ZipFile.ExtractToDirectory(tempZip, targetPath);

                MessageBox.Show($"TDM CLIs extracted to:\n{targetPath}", "Success", MessageBoxButton.OK, MessageBoxImage.Information);
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Failed to install TDM CLIs:\n{ex.Message}", "Error", MessageBoxButton.OK, MessageBoxImage.Error);
            }
        }
        private void OnTdmRootTextChanged(object sender, TextChangedEventArgs e)
        {
            var path = TdmRootTextBox.Text;
            if (Directory.Exists(path))
            {
                // Future: auto-load config files or validate folder here
                // e.g., load available *.conf files, or enable a "Continue" button
            }
        }

        private void OnAuthenticateTdmClicked(object sender, RoutedEventArgs e)
        {
            RunStep("Authenticate-Tdm.ps1");
        }


    }
}
