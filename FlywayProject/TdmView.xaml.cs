using Microsoft.VisualStudio.Package;
using System;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Windows;
using System.Windows.Controls;

namespace FlywayProject
{
    public partial class TdmView : UserControl
    {
        private readonly string stepsFolder = "C:/Users/Huxley.Kendell/Source/Repos/SecretP48/tdmAP/Steps/Windows";
        private readonly string subsetOptionsFolder = "C:/Users/Huxley.Kendell/Source/Repos/SecretP48/tdmAP/Subset";
        private readonly string maskingOptionsFolder = "C:/Users/Huxley.Kendell/Source/Repos/SecretP48/tdmAP/Masking";

        public TdmView()
        {
            InitializeComponent();
            LoadSubsetOptions();
            LoadMaskingOptions();
        }

        private void LoadSubsetOptions()
        {
            if (!Directory.Exists(subsetOptionsFolder)) return;

            var files = Directory.GetFiles(subsetOptionsFolder, "*.json");
            foreach (var file in files)
            {
                SubsetOptionsComboBox.Items.Add(Path.GetFileName(file));
            }

            if (SubsetOptionsComboBox.Items.Count > 0)
                SubsetOptionsComboBox.SelectedIndex = 0;
        }

        private void LoadMaskingOptions()
        {
            if (!Directory.Exists(maskingOptionsFolder)) return;

            var files = Directory.GetFiles(maskingOptionsFolder, "*.json");
            foreach (var file in files)
            {
                MaskingOptionsComboBox.Items.Add(Path.GetFileName(file));
            }

            if (MaskingOptionsComboBox.Items.Count > 0)
                MaskingOptionsComboBox.SelectedIndex = 0;
        }

        private void RunStep(string scriptName, string arguments = "")
        {
            string basePath = "C:\\Users\\Huxley.Kendell\\Source\\Repos\\SecretP48";
            string scriptPath = Path.Combine(basePath, "tdmAP", "Steps", "Windows", scriptName);
            string modulePath = Path.Combine(basePath, "tdmAP", "Setup_Files", "helper-functions.psm1");

            if (!File.Exists(scriptPath))
            {
                MessageBox.Show($"Script not found: {scriptPath}", "Error", MessageBoxButton.OK, MessageBoxImage.Error);
                return;
            }

            if (!File.Exists(modulePath))
            {
                MessageBox.Show($"Helper module not found: {modulePath}", "Error", MessageBoxButton.OK, MessageBoxImage.Error);
                return;
            }

            string command = $"Import-Module '{modulePath}'; . '{scriptPath}' {arguments}";

            try
            {
                Process.Start(new ProcessStartInfo
                {
                    FileName = "powershell.exe",
                    Arguments = $"-ExecutionPolicy Bypass -Command \"{command}\"",
                    UseShellExecute = true
                });
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Failed to run script:\n{ex.Message}", "Error", MessageBoxButton.OK, MessageBoxImage.Error);
            }
        }

        private void OnCreateDatabasesClicked(object sender, RoutedEventArgs e)
        {
            string args = "-winAuth:'Y' -sqlInstance:localhost -sourceDb:'AutoPilotRestore' -targetDb:'AutoPilotSubset'";
            RunStep("03b_Provision-Databases.ps1", args);

        }

        private void OnRunSubsetClicked(object sender, RoutedEventArgs e)
        {
            if (SubsetOptionsComboBox.SelectedItem is string optionFile)
            {
                string optionPath = Path.Combine(subsetOptionsFolder, optionFile);
                RunStep("01_Subset-Data.ps1", $"-optionsFile \"{optionPath}\"");
            }
        }

        private void OnGenerateClassificationClicked(object sender, RoutedEventArgs e)
        {
            RunStep("02_Classify-Data.ps1");
        }

        private void OnGenerateMaskingFileClicked(object sender, RoutedEventArgs e)
        {
            RunStep("03_Generate-Masking-File.ps1");
        }

        private void OnRunMaskingClicked(object sender, RoutedEventArgs e)
        {
            if (MaskingOptionsComboBox.SelectedItem is string maskingFile)
            {
                string path = Path.Combine(maskingOptionsFolder, maskingFile);
                RunStep("04_Mask-Data.ps1", $"-maskingFile \"{path}\"");
            }
            else
            {
                RunStep("04_Mask-Data.ps1");
            }
        }

        private void SubsetOptionsComboBox_SelectionChanged(object sender, SelectionChangedEventArgs e)
        {

        }
    }
}
