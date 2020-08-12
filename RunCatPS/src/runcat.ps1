Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# �J�����g�f�B���N�g�����擾
$path = Split-Path -Parent $MyInvocation.MyCommand.Path

# �E�B���h�E���\����
$cscode = @"
// Win32Api ��ǂݍ��ނ��߂� C# �R�[�h
[DllImport("user32.dll")]
[return: MarshalAs(UnmanagedType.Bool)]
// �E�B���h�E�̏�Ԃ𐧌䂷�邽�� ShowWindowAsync() �� extern ����
public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);
"@
$Win32Functions = Add-Type -MemberDefinition $cscode -name Win32ShowWindowAsync -namespace Win32Functions -PassThru
$Win32Functions::ShowWindowAsync((Get-Process -PID $pid).MainWindowHandle, 0) > $null # bool �l��Ԃ��̂� null �Ɏ̂Ă�

# �^�X�N�g���C�ɃA�C�R�����쐬����
$notifyIcon = New-Object System.Windows.Forms.NotifyIcon
$notifyIcon.Visible = $true

# �_�[�N���[�h����
$theme = "light"
if ((Get-ItemProperty -Path "Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize").AppsUseLightTheme -eq 0) {
    $theme = "dark"
}

# ���\�[�X�̓ǂ݂���
$cats = @(
    New-Object System.Drawing.Icon -ArgumentList "$path\\resources\\${theme}_cat0.ico";
    New-Object System.Drawing.Icon -ArgumentList "$path\\resources\\${theme}_cat1.ico";
    New-Object System.Drawing.Icon -ArgumentList "$path\\resources\\${theme}_cat2.ico";
    New-Object System.Drawing.Icon -ArgumentList "$path\\resources\\${theme}_cat3.ico";
    New-Object System.Drawing.Icon -ArgumentList "$path\\resources\\${theme}_cat4.ico"
)

# CPU�g�p�������I�Ɏ擾���邽�߁A�^�C�}�[�I�u�W�F�N�g���쐬����
$cpuTimer = New-Object Windows.Forms.Timer

# �^�C�}�[�̃C�x���g�n���h��������������݂����ϐ��� script �X�R�[�v�Ő錾
$script:jobId = $null
$script:idx = 0 
$script:cpuUsage = 0.0

$cpuTimer.Add_Tick( {
        $cpuTimer.Stop()

        # CPU ���ׂ̎擾�� GUI �v���Z�X���u���b�N���Ȃ��悤�A�o�b�N�O���E���h�W���u�Ƃ��ď������s��
        $script:jobId = (Start-Job -ScriptBlock {
                [double]((Get-Counter -Counter  "\Processor(_Total)\% Processor Time").CounterSamples).CookedValue 
            }).Id 

        $cpuTimer.Start()
    })
  
$cpuTimer.Interval = 3000
$cpuTimer.Start()

# �^�X�N�g���C�A�C�R����C�ӂ̃^�C�~���O�ō����ւ��邽�߁A�^�C�}�[�I�u�W�F�N�g���쐬����
$animateTimer = New-Object Windows.Forms.Timer

$animateTimer.Add_Tick( {
        $animateTimer.Stop()
  
        # ���̃R�}��\��
        $notifyIcon.Icon = $cats[$script:idx++]
        if ($script:idx -eq 5) { $script:idx = 0 }

        # CPU �g�p�����o�b�N�O���E���h�������ʂ���擾
        if ($script:jobId -ne $null) {
            $u = (Receive-Job -Id $script:jobId)
            # CPU �g�p���ɕω����������Ƃ�
            if ($u -ne $null) { 
                $script:cpuUsage = $u 
                $notifyIcon.Text = $script:cpuUsage
                # �l�R�`�����̑�����ύX
                $animateTimer.Interval = (200.0 / [System.Math]::Max(1.0, [System.Math]::Min(20.0, $script:cpuUsage / 5)))
            }           
        }

        $animateTimer.Start()
    })
  
$animateTimer.Interval = 200
$animateTimer.Start()

# ���b�Z�[�W���[�v�ŗ��p���� ApplicationContext ���쐬����
$applicationContext = New-Object System.Windows.Forms.ApplicationContext
  
# �A�C�R���N���b�N���̃C�x���g�n���h��
$notifyIcon.add_Click( {
        # ���b�Z�[�W���[�v���I��
        $applicationContext.ExitThread() 
    })

# �A�C�R���������܂ŏI���Ȃ��悤�A���b�Z�[�W���[�v����
[System.Windows.Forms.Application]::Run($applicationContext)

$cpuTimer.Stop()
$animateTimer.Stop()
$notifyIcon.Visible = $false