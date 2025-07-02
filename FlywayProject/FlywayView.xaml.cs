using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Windows;
using System.Windows.Controls;
using Tomlyn;
using WinForms = System.Windows.Forms;

namespace FlywayProject
{
    public partial class FlywayView : UserControl
    {
        private string flywayConfigPath;

        public FlywayView()
        {
            InitializeComponent();
        }

        private void RunStep(string scriptName, string extraArgs = "")
        {
            string stepsFolder = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "Steps", "Windows");
            string scriptPath = Path.Combine(stepsFolder, scriptName);

            if (!File.Exists(scriptPath))
            {
                MessageBox.Show($"Script not found: {scriptPath}", "Error", MessageBoxButton.OK, MessageBoxImage.Error);
                return;
            }

            try
            {
                var psi = new ProcessStartInfo
                {
                    FileName = "pwsh.exe",
                    Arguments = $"-NoExit -ExecutionPolicy Bypass -File \"{scriptPath}\" {extraArgs}".Trim(),
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

        private void OnFlywayConfigPathChanged(object sender, TextChangedEventArgs e)
        {
            // Wait until user confirms
        }

        private void OnBrowseFlywayConfigClicked(object sender, RoutedEventArgs e)
        {
            var dialog = new WinForms.FolderBrowserDialog
            {
                Description = "Select your Flyway project folder"
            };

            if (dialog.ShowDialog() == WinForms.DialogResult.OK)
            {
                FlywayConfigFileTextBox.Text = dialog.SelectedPath;
            }
        }

        private void OnConfirmFlywayConfigClicked(object sender, RoutedEventArgs e)
        {
            var folderPath = FlywayConfigFileTextBox.Text.Trim();
            var configPath = Path.Combine(folderPath, "flyway.toml");

            if (!Directory.Exists(folderPath) || !File.Exists(configPath))
            {
                MessageBox.Show("flyway.toml not found in that folder.", "Error", MessageBoxButton.OK, MessageBoxImage.Warning);
                return;
            }

            flywayConfigPath = configPath;

            // Set folder in other tabs
            FlywayDirBox.Text = folderPath;
            TempFlywayDirBox.Text = folderPath;

            try
            {
                string tomlText = File.ReadAllText(configPath);
                var model = Toml.Parse(tomlText).ToModel();

                if (model is IDictionary<string, object> root &&
                    root.TryGetValue("environments", out var envsRaw) &&
                    envsRaw is IDictionary<string, object> environments)
                {
                    FlywaySourceEnvComboBox.Items.Clear();
                    FlywayTargetEnvComboBox.Items.Clear();

                    foreach (var env in environments.Keys)
                    {
                        FlywaySourceEnvComboBox.Items.Add(env);
                        FlywayTargetEnvComboBox.Items.Add(env);
                    }

                    if (FlywaySourceEnvComboBox.Items.Count > 0)
                        FlywaySourceEnvComboBox.SelectedIndex = 0;
                    if (FlywayTargetEnvComboBox.Items.Count > 0)
                        FlywayTargetEnvComboBox.SelectedIndex = 0;
                }

                MessageBox.Show("Flyway config confirmed and environments loaded.", "Success", MessageBoxButton.OK, MessageBoxImage.Information);
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Failed to parse flyway.toml:\n{ex.Message}", "Parse Error", MessageBoxButton.OK, MessageBoxImage.Error);
            }
        }

        private void OnTestConnectionClicked(object sender, RoutedEventArgs e)
        {
            RunStep("03a_Create-ConnectionStrings.ps1");
        }

        private void OnInstallFlywayClisClicked(object sender, RoutedEventArgs e)
        {
            MessageBox.Show("Install Flyway CLI not implemented.");
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

        private void OnAuthenticateFWClicked(object sender, RoutedEventArgs e)
        {
            try
            {
                Process.Start(new ProcessStartInfo
                {
                    FileName = "pwsh.exe",
                    Arguments = "-ExecutionPolicy Bypass -File \"Authenticate-Flyway.ps1\" -iAgreeToTheRedgateEula",
                    UseShellExecute = true
                });
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Failed to authenticate: {ex.Message}");
            }
        }

        private void OnCaptureClicked(object sender, RoutedEventArgs e)
        {
            string flywayDir = TempFlywayDirBox.Text.Trim();
            string sourceEnv = FlywaySourceEnvComboBox.SelectedItem?.ToString()?.Trim();

            if (string.IsNullOrWhiteSpace(flywayDir) || string.IsNullOrWhiteSpace(sourceEnv))
            {
                MessageBox.Show("Please select the Flyway directory and source environment.");
                return;
            }

            string modelPath = Path.Combine(flywayDir, "schema-model");
            string artifactPath = Path.Combine(flywayDir, "Artifact", "capture.sql");

            string command = $"diff model " +
                             $"-diff.source={sourceEnv} " +
                             "-diff.target=schemaModel " +
                             $"-diff.artifactFilename=\"{artifactPath}\" " +
                             $"-model.artifactFilename=\"{artifactPath}\" " +
                             $"-configFiles=\"{flywayConfigPath}\" " +
                             $"-schemaModelLocation=\"{modelPath}\"";

            try
            {
                Process.Start(new ProcessStartInfo
                {
                    FileName = "cmd.exe",
                    Arguments = $"/k flyway {command}",
                    WorkingDirectory = flywayDir,
                    UseShellExecute = true
                });
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Failed to run Flyway diff:\n{ex.Message}");
            }
        }

        private void OnDeployClicked(object sender, RoutedEventArgs e)
        {
            string flywayDir = FlywayDirBox.Text.Trim();
            string source = FlywaySourceEnvComboBox.SelectedItem?.ToString()?.Trim();
            string target = FlywayTargetEnvComboBox.SelectedItem?.ToString()?.Trim();
            string additional = FlywayParamsBox.Text.Trim();

            if (string.IsNullOrWhiteSpace(flywayDir) || string.IsNullOrWhiteSpace(source) || string.IsNullOrWhiteSpace(target))
            {
                MessageBox.Show("Please fill in all required fields (Flyway Directory, Source, Target).");
                return;
            }

            string command =
                $"prepare deploy " +
                $"-prepare.source={source} " +
                $"-prepare.target={target} " +
                $"-environment={target} " +
                $"-environments.{target}.user=REPLACE_ME " +
                $"-environments.{target}.password=REPLACE_ME " +
                $"-prepare.scriptFilename=\"{flywayDir}\\Artifact\\migration.sql\" " +
                $"-deploy.scriptFilename=\"{flywayDir}\\Artifact\\migration.sql\" " +
                "-prepare.force=true " +
                $"-configFiles=\"{flywayConfigPath}\" " +
                $"-schemaModelLocation=\"{flywayDir}\\schema-model\" " +
                "-cleanDisabled=false " +
                additional;

            try
            {
                Process.Start(new ProcessStartInfo
                {
                    FileName = "cmd.exe",
                    Arguments = $"/k flyway {command}",
                    WorkingDirectory = flywayDir,
                    UseShellExecute = true
                });
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Failed to run Flyway:\n{ex.Message}");
            }
        }
    }
}
