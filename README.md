# all work is done by phh https://github.com/phhusson/treble_experimentations.git

I just wanted to make it a little easier for rom devs to start building a little faster!

# inital install

mkdir android (or whatever name you want your root dir to be)

git clone https://github.com/skunkworkx-gsi/vendor_aosp.git -b q vendor/aosp

cd vendor/aosp/treble

bash first_install.sh 

# after inital install

cd ../../../

bash build_treble.sh
