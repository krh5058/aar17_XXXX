function [frame] = javaui()
% javaui.m
% 8/7/13
% Author: Ken Hwang

% Import
import javax.swing.*
import javax.swing.table.*
import java.awt.*

% Set-up JFrame
frame = JFrame('Experiment Info');
callback4 = @(obj,evt)onClose(obj,evt); % Callback for close button
set(frame,'WindowClosingCallback',callback4);
frame.setSize(400,300);
toolkit = Toolkit.getDefaultToolkit();
screenSize = toolkit.getScreenSize();
x = (screenSize.width - frame.getWidth()) / 2;
y = (screenSize.height - frame.getHeight()) / 2;
frame.setLocation(x, y);

% Set-up subject ID entry
tf1Panel = JPanel(GridLayout(1,1));
tf1 = JTextField(datestr(now,30));
t1 = BorderFactory.createTitledBorder('Subject ID:');
tf1Panel.setBorder(t1);
tf1Panel.add(tf1);

% Set-up subject ID entry
tf2Panel = JPanel(GridLayout(1,1));
tf2 = JTextField('2500');
t2 = BorderFactory.createTitledBorder('TR (ms):');
tf2Panel.setBorder(t2);
tf2Panel.add(tf2);

% Set-up subject ID entry
tf3Panel = JPanel(GridLayout(1,1));
tf3 = JTextField();
t3 = BorderFactory.createTitledBorder('Stop Delay (ms):');
tf3Panel.setBorder(t3);
tf3Panel.add(tf3);

% Set-up left pane
left = JPanel(GridLayout(3,1));
left.setMinimumSize(Dimension(150,225));
left.setPreferredSize(Dimension(150,225));
left.add(tf1Panel);
left.add(tf2Panel);
left.add(tf3Panel);

% Set-up trigger radio buttons
rb1Panel = JPanel(GridLayout(2,1));
r1 = BorderFactory.createTitledBorder('Trigger:');
rb1Panel.setBorder(r1);
yes1 = JRadioButton('Yes');
yes1.setActionCommand('Yes');
yes1.setSelected(true);
no1 = JRadioButton('No');
no1.setActionCommand('No');

group1 = ButtonGroup();
group1.add(yes1);
group1.add(no1);

rb1Panel.add(yes1);
rb1Panel.add(no1);

% Set-up run radio buttons
rb2Panel = JPanel(GridLayout(4,1));
r2 = BorderFactory.createTitledBorder('Start at Run:');
rb2Panel.setBorder(r2);
run1 = JRadioButton('1');
run1.setActionCommand('1');
run1.setSelected(true);
run2 = JRadioButton('2');
run2.setActionCommand('2');
run3 = JRadioButton('3');
run3.setActionCommand('3');
run4 = JRadioButton('4');
run4.setActionCommand('4');

group2 = ButtonGroup();
group2.add(run1);
group2.add(run2);
group2.add(run3);
group2.add(run4);

rb2Panel.add(run1);
rb2Panel.add(run2);
rb2Panel.add(run3);
rb2Panel.add(run4);

% Set-up entire right pane
right = JPanel(GridLayout(2,1));
right.setMinimumSize(Dimension(250,225));
right.setPreferredSize(Dimension(250,225));
right.add(rb1Panel);
right.add(rb2Panel);

% Set-up confirm button
confirm = JButton('Confirm');
cbh = handle(confirm,'CallbackProperties');
callback1 = @(obj,evt)onConfirm(obj,evt);
set(cbh,'MouseClickedCallback', callback1);

% Set-up bottom pane
bot = JPanel();
bot.setMinimumSize(Dimension(400,75));
bot.setPreferredSize(Dimension(400,75));
bot.add(confirm);

% Split left and right
splitpane1 = JSplitPane(JSplitPane.HORIZONTAL_SPLIT,left,right);
splitpane1.setEnabled(false);

% Split top and bottom
splitpane2 = JSplitPane(JSplitPane.VERTICAL_SPLIT,splitpane1,bot);
splitpane2.setEnabled(false);

frame.add(splitpane2);

frame.setResizable(0);
frame.setVisible(1);

    function onConfirm(obj,evt) % When confirm button is pressed
        sid = tf1.getText();
        tr = tf2.getText();
        Z = tf3.getText();
        
        selectedModel1 = group1.getSelection();
        trig = selectedModel1.getActionCommand();
        selectedModel2 = group2.getSelection();
        runstart = selectedModel2.getActionCommand();
        
        if isempty(char(sid)) % Check for empty SID
            javax.swing.JOptionPane.showMessageDialog(frame,'Subject ID is empty!','Subject ID check',javax.swing.JOptionPane.INFORMATION_MESSAGE);
        elseif isempty(char(tr)) % Check for empty TR
            javax.swing.JOptionPane.showMessageDialog(frame,'TR is empty!','TR check',javax.swing.JOptionPane.INFORMATION_MESSAGE);
        elseif isempty(char(Z)) % Check for empty Z
            javax.swing.JOptionPane.showMessageDialog(frame,'Stop Delay is empty!','Stop Delay check',javax.swing.JOptionPane.INFORMATION_MESSAGE); 
        else
            
            % Parameter confirmation
            infostring = sprintf(['Subject ID: ' char(sid) ...
                '\nTR: ' char(tr) ...
                '\nStop Delay: ' char(Z) ...
                '\nTrigger: ' char(trig) ...
                '\nStart at Run: ' char(runstart) ...
                '\n\nIs this correct?']);
            result = javax.swing.JOptionPane.showConfirmDialog(frame,infostring,'Confirm parameters',javax.swing.JOptionPane.YES_NO_OPTION);
            
            % Record data and close
            if result==javax.swing.JOptionPane.YES_OPTION 
                switch char(trig)
                    case 'Yes'
                        trig = 1;
                    case 'No'
                        trig = 0;
                end
                setappdata(frame,'UserData',{char(sid),str2num(tr),str2num(Z),trig,str2double(runstart)});
                frame.dispose();
            else
            end
        end
    end

    function onClose(obj,evt) % When close button on frame is pressed
        setappdata(frame,'UserData',[]);
        frame.setVisible(0);
        frame.dispose();
    end
end